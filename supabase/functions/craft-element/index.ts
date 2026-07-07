// Supabase Edge Function: craft-element
//
// Stage 3 of the craft pipeline. Receives two element names and a
// `language` ('en' | 'tr2' | 'de' | 'es' | 'pt'), asks an LLM to invent
// the resulting element, and — new in v2 — WRITES the result to the
// per-language combinations table itself using the service role.
// Clients no longer insert into those tables at all (their RLS insert
// policies are dropped), which closes the data-poisoning hole where
// anyone with the anon key could write arbitrary rows.
//
// Also enforces a simple per-user rate limit (via the `bump_craft_rate`
// SQL function) so a hostile client can't burn the LLM quotas.
//
// Key strategy:
// - EN       : Groq (Llama 3.3 70B) → OpenRouter free pool fallback.
// - TR2      : Groq → OpenRouter free pool → Gemini (last resort).
// - DE/ES/PT : OpenRouter paid key, cheap/fast small model (beta).
//
// Secrets:
//   GROQ_API_KEY         — Groq (Llama 3.3 70B) for EN + TR2
//   OPENROUTER_PAID_KEY  — tek ücretli key (DE/ES/PT + EN/TR2 fallback)
//   OPENROUTER_FREE_KEYS — virgülle ayrılmış ücretsiz key havuzu
//   GEMINI_API_KEY       — TR2 için son çare fallback
//   (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are injected automatically.)

import { createClient } from "npm:@supabase/supabase-js@2";

function parseKeyPool(raw: string | undefined): string[] {
  return (raw ?? "").split(",").map((k) => k.trim()).filter((k) => k.length > 0);
}
function pickRandom(pool: string[], name: string): string {
  if (pool.length === 0) throw new Error(`${name} is not configured`);
  return pool[Math.floor(Math.random() * pool.length)];
}

const PAID_KEY  = Deno.env.get("OPENROUTER_PAID_KEY") ?? "";
const FREE_KEYS = parseKeyPool(Deno.env.get("OPENROUTER_FREE_KEYS"));

const OPENROUTER_URL         = "https://openrouter.ai/api/v1/chat/completions";
const OPENROUTER_FREE_MODEL  = "openrouter/free";
const OPENROUTER_BETA_MODEL  = "meta-llama/llama-3.1-8b-instruct";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const GROQ_URL   = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "llama-3.3-70b-versatile";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = "gemini-2.5-flash";

// Service-role client: bypasses RLS, used for the combinations writes and
// the rate-limit counter. Never exposed to the caller.
const service = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Max LLM crafts per user per minute. Cached/stage-2 lookups never reach
// this function, so legitimate play stays far below the cap.
const RATE_LIMIT_PER_MINUTE = 12;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Thrown when the upstream LLM API itself fails (HTTP error) - distinct
// from a malformed/unexpected response, which is a 500.
class LlmHttpError extends Error {}

// ── Language / table helpers (mirrors lib/core/utils/combination_key.dart) ──

const TABLE_FOR: Record<string, string> = {
  en: "combinations",
  tr2: "v2_combinations",
  de: "de_combinations",
  es: "es_combinations",
  pt: "pt_combinations",
};

const KEY_PREFIX: Record<string, string> = {
  en: "",
  tr2: "tr2:",
  de: "de:",
  es: "es:",
  pt: "pt:",
};

function combinationKey(a: string, b: string, language: string): string {
  const na = a.toLowerCase().trim();
  const nb = b.toLowerCase().trim();
  const [x, y] = [na, nb].sort();
  return `${KEY_PREFIX[language]}${x}+${y}`;
}

// ── Content guards ──────────────────────────────────────────────────────────

// Minimal profanity blocklist (EN+TR). A blocked result is treated as
// "no combination" rather than shown to players. Deliberately short —
// this is a safety net for rare LLM slips, not a moderation system.
const BLOCKED_WORDS = [
  "fuck", "shit", "bitch", "cunt", "nigger", "faggot", "dick", "cock",
  "porn", "rape",
  "amk", "aq", "orospu", "piç", "yarrak", "sik", "amcık", "göt deliği",
  "kahpe", "pezevenk", "tecavüz",
];

function isBlocked(name: string): boolean {
  const lower = name.toLowerCase();
  return BLOCKED_WORDS.some((w) => lower.includes(w));
}

// Keep only values that actually contain pictographic characters; the LLM
// occasionally returns words (any script) in the emoji field.
function sanitizeEmoji(value: string): string {
  const trimmed = value.trim();
  if (!trimmed || !/\p{Extended_Pictographic}/u.test(trimmed)) return "❔";
  return trimmed.length > 16 ? "❔" : trimmed;
}

// ── Prompts ────────────────────────────────────────────────────────────────

function englishPrompt(elementA: string, elementB: string): string {
  return (
    `You are the combination engine of an "Infinite Craft" game.\n\n` +
    `Combine: "${elementA}" + "${elementB}"\n\n` +
    `OUTPUT RULES (apply in order):\n` +
    `1. Return ONLY 1 word. If truly impossible, use 2 words. Never more than 2.\n` +
    `2. The result MUST NOT contain "${elementA}" or "${elementB}". It must be a completely new concept.\n` +
    `3. ENGLISH ONLY. No made-up words.\n` +
    `4. If there is no logical connection: {"name": null, "emoji": null}\n\n` +
    `Examples:\n` +
    `- Water + Fire → {"name": "Steam", "emoji": "💨"}\n` +
    `- Human + Fire → {"name": "Blacksmith", "emoji": "⚒️"}\n` +
    `- Dragon + Wind → {"name": "Hurricane", "emoji": "🌪️"}\n` +
    `- Gold + Earth → {"name": "Mine", "emoji": "⛏️"}\n` +
    `- Ice + Fire → {"name": "Mist", "emoji": "🌫️"}\n` +
    `- Ocean + Wind → {"name": "Wave", "emoji": "🌊"}\n` +
    `- Tree + Lightning → {"name": "Ash", "emoji": "🌑"}\n` +
    `- Robot + Human → {"name": "Cyborg", "emoji": "🤖"}\n\n` +
    `Return ONLY JSON, nothing else:\n` +
    `{"name": "...", "emoji": "..."}`
  );
}

// DE/ES/PT are "beta" — kept minimal on purpose to stay cheap and fast on
// a small OpenRouter model. No few-shot examples, just the bare rule.
function germanPrompt(elementA: string, elementB: string): string {
  return (
    `"Infinite Craft" Spiel. Kombiniere "${elementA}" + "${elementB}" zu einem ` +
    `neuen deutschen Wort/Konzept (1-2 Wörter, nicht "${elementA}" oder "${elementB}"). ` +
    `Keine logische Verbindung → {"name": null, "emoji": null}. ` +
    `Nur JSON: {"name": "...", "emoji": "..."}`
  );
}

function spanishPrompt(elementA: string, elementB: string): string {
  return (
    `Juego "Infinite Craft". Combina "${elementA}" + "${elementB}" en una ` +
    `nueva palabra/concepto en español (1-2 palabras, no "${elementA}" ni "${elementB}"). ` +
    `Sin conexión lógica → {"name": null, "emoji": null}. ` +
    `Solo JSON: {"name": "...", "emoji": "..."}`
  );
}

function portuguesePrompt(elementA: string, elementB: string): string {
  return (
    `Jogo "Infinite Craft". Combine "${elementA}" + "${elementB}" em uma ` +
    `nova palavra/conceito em português (1-2 palavras, não "${elementA}" nem "${elementB}"). ` +
    `Apenas JSON: {"name": "...", "emoji": "..."} ou sem conexão lógica → {"name": null, "emoji": null}.`
  );
}

function turkishV2Prompt(elementA: string, elementB: string): string {
  return (
    `Sen "Infinite Craft" oyununun Türkçe birleşim motorusun.\n\n` +
    `Birleştir: "${elementA}" + "${elementB}"\n\n` +
    `ÇIKTI KURALLARI (sırasıyla uygula):\n` +
    `1. SADECE tek kelime dön. Eğer tek kelime bulamazsan iki kelime. Asla ikiden fazla kelime kullanma.\n` +
    `2. Sonuç KESİNLİKLE "${elementA}" veya "${elementB}" kelimelerini içeremez. Tamamen yeni bir kavram olmalı.\n` +
    `3. SADECE TÜRKÇE. İngilizce, Latince, yabancı kelime kesinlikle yasak.\n` +
    `4. Türkçe karakterleri doğru kullan: ç, ğ, ı, ö, ş, ü.\n` +
    `5. Mantıklı bağlantı yoksa: {"name": null, "emoji": null}\n\n` +
    `Örnekler:\n` +
    `- Su + Ateş → {"name": "Buhar", "emoji": "💨"}\n` +
    `- İnsan + Ateş → {"name": "Demirci", "emoji": "⚒️"}\n` +
    `- Ejderha + Rüzgar → {"name": "Kasırga", "emoji": "🌪️"}\n` +
    `- Altın + Toprak → {"name": "Maden", "emoji": "⛏️"}\n` +
    `- Buz + Ateş → {"name": "Sis", "emoji": "🌫️"}\n` +
    `- Okyanus + Rüzgar → {"name": "Dalga", "emoji": "🌊"}\n` +
    `- Ağaç + Şimşek → {"name": "Kül", "emoji": "🌑"}\n` +
    `- Robot + İnsan → {"name": "Yapay Zeka", "emoji": "🧠"}\n\n` +
    `SADECE JSON döndür, başka hiçbir şey yazma:\n` +
    `{"name": "...", "emoji": "..."}`
  );
}

// ── LLM callers ────────────────────────────────────────────────────────────

async function callOpenRouter(prompt: string, apiKey: string, model: string) {
  const response = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [{ role: "user", content: prompt }],
      response_format: { type: "json_object" },
      temperature: 0.4,
    }),
  });
  return { ok: response.ok, status: response.status, data: response };
}

async function callGroq(prompt: string) {
  if (!GROQ_API_KEY) throw new Error("GROQ_API_KEY is not configured");
  const response = await fetch(GROQ_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${GROQ_API_KEY}`,
    },
    body: JSON.stringify({
      model: GROQ_MODEL,
      messages: [{ role: "user", content: prompt }],
      response_format: { type: "json_object" },
      temperature: 0.4,
    }),
  });
  return { ok: response.ok, status: response.status, data: response };
}

// EN: Groq (Llama 3.3 70B) → OpenRouter free pool. The Groq call itself is
// wrapped so a network-level failure (not just an HTTP error) still falls
// through to the next provider instead of aborting the whole chain.
async function craftWithGroqThenFree(prompt: string) {
  try {
    const first = await callGroq(prompt);
    if (first.ok) {
      const data = await first.data.json();
      return JSON.parse(data.choices[0].message.content);
    }
  } catch (_) {
    // Groq unreachable — fall through to OpenRouter.
  }

  const freeKey = pickRandom(FREE_KEYS, "OPENROUTER_FREE_KEYS");
  const second = await callOpenRouter(prompt, freeKey, OPENROUTER_FREE_MODEL);
  if (!second.ok) {
    throw new LlmHttpError(`Groq+OpenRouter fallback error: ${await second.data.text()}`);
  }
  const data = await second.data.json();
  return JSON.parse(data.choices[0].message.content);
}

// DE/ES/PT: "beta" languages — OpenRouter paid key, a very cheap/fast
// small model. Quality isn't a priority here, just existing + being snappy.
async function craftBeta(prompt: string) {
  if (!PAID_KEY) throw new Error("OPENROUTER_PAID_KEY is not configured");
  const res = await callOpenRouter(prompt, PAID_KEY, OPENROUTER_BETA_MODEL);
  if (!res.ok) {
    throw new LlmHttpError(`OpenRouter beta error: ${await res.data.text()}`);
  }
  const data = await res.data.json();
  return JSON.parse(data.choices[0].message.content);
}

async function craftWithGemini(prompt: string, apiKey: string) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY is not configured");
  }

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.4, responseMimeType: "application/json" },
    }),
  });

  if (!response.ok) {
    throw new LlmHttpError(`Gemini error: ${await response.text()}`);
  }

  const data = await response.json();
  const text = data.candidates[0].content.parts[0].text;
  return JSON.parse(text);
}

// TR2 (the active Turkish module): Groq → OpenRouter free pool → Gemini,
// in that order. Groq/OpenRouter already cover the vast majority of
// requests at effectively $0 - Gemini is kept alive purely as this chain's
// last resort, only called when both of those fail/error for a request.
async function craftTr2(elementA: string, elementB: string) {
  const prompt = turkishV2Prompt(elementA, elementB);

  try {
    const first = await callGroq(prompt);
    if (first.ok) {
      const data = await first.data.json();
      return JSON.parse(data.choices[0].message.content);
    }
  } catch (_) {
    // Groq unreachable — fall through.
  }

  try {
    const freeKey = pickRandom(FREE_KEYS, "OPENROUTER_FREE_KEYS");
    const second = await callOpenRouter(prompt, freeKey, OPENROUTER_FREE_MODEL);
    if (second.ok) {
      const data = await second.data.json();
      return JSON.parse(data.choices[0].message.content);
    }
  } catch (_) {
    // OpenRouter down/erroring too — fall through to Gemini below.
  }

  return await craftWithGemini(prompt, GEMINI_API_KEY);
}

// ── Server-side persistence ────────────────────────────────────────────────

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/// Writes the crafted (or "no combination") row and returns the canonical
/// stored result — if a concurrent request already inserted this pair, the
/// earlier row wins and is what gets returned to everyone.
async function persistAndCanonicalize(
  language: string,
  a: string,
  b: string,
  result: { name: string | null; emoji: string | null },
  userId: string,
) {
  const table = TABLE_FOR[language];
  const pairKey = combinationKey(a, b, language);

  if (result.name === null) {
    await service.from(table).upsert(
      {
        pair_key: pairKey,
        element_a: a.toLowerCase().trim(),
        element_b: b.toLowerCase().trim(),
        no_combination: true,
        discovered_by: userId,
      },
      { onConflict: "pair_key", ignoreDuplicates: true },
    );
    return { name: null, emoji: null, isFirstDiscovery: false };
  }

  const resultName = result.name;
  const resultEmoji = sanitizeEmoji(result.emoji ?? "");

  // World-first check: has any pair in this language already produced this
  // element name? (Language tables are already namespaced, but pair_key
  // prefixes are kept for defense-in-depth on the shared `combinations`.)
  let existingQuery = service
    .from(table)
    .select("pair_key")
    .ilike("result_name", resultName);
  if (KEY_PREFIX[language]) {
    existingQuery = existingQuery.like("pair_key", `${KEY_PREFIX[language]}%`);
  }
  const { data: existing } = await existingQuery.limit(1).maybeSingle();
  const isFirstDiscovery = existing === null;

  await service.from(table).upsert(
    {
      pair_key: pairKey,
      element_a: a.toLowerCase().trim(),
      element_b: b.toLowerCase().trim(),
      result_name: resultName,
      result_emoji: resultEmoji,
      is_first_discovery: isFirstDiscovery,
      discovered_by: userId,
    },
    { onConflict: "pair_key", ignoreDuplicates: true },
  );

  // Return whatever actually ended up stored (handles insert races).
  const { data: row } = await service
    .from(table)
    .select()
    .eq("pair_key", pairKey)
    .maybeSingle();

  if (row?.no_combination === true) {
    return { name: null, emoji: null, isFirstDiscovery: false };
  }
  return {
    name: (row?.result_name as string) ?? resultName,
    emoji: (row?.result_emoji as string) ?? resultEmoji,
    // Only celebrate a world-first if the stored row is one AND this caller
    // is the one who stored it (a lost insert race means someone else was
    // first with this exact pair a moment ago).
    isFirstDiscovery:
      row == null
        ? isFirstDiscovery
        : row.is_first_discovery === true && row.discovered_by === userId,
  };
}

// ── Handler ────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Identify the caller from their JWT (anonymous sessions included).
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const { data: userData } = await service.auth.getUser(token);
    const userId = userData?.user?.id;
    if (!userId) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    // Per-user rate limit (atomic counter in SQL, see craft_hardening.sql).
    const { data: hits, error: rateError } = await service.rpc(
      "bump_craft_rate",
      { p_user: userId },
    );
    if (!rateError && typeof hits === "number" && hits > RATE_LIMIT_PER_MINUTE) {
      return jsonResponse({ error: "rate limit exceeded" }, 429);
    }

    const { elementA, elementB, language } = await req.json();

    if (!elementA || !elementB || typeof elementA !== "string" ||
        typeof elementB !== "string" || elementA.length > 60 ||
        elementB.length > 60) {
      return jsonResponse({ error: "elementA and elementB are required" }, 400);
    }
    const lang = TABLE_FOR[language] ? language : "en";

    const result = lang === "de"
      ? await craftBeta(germanPrompt(elementA, elementB))
      : lang === "es"
      ? await craftBeta(spanishPrompt(elementA, elementB))
      : lang === "pt"
      ? await craftBeta(portuguesePrompt(elementA, elementB))
      : lang === "tr2"
      ? await craftTr2(elementA, elementB)
      : await craftWithGroqThenFree(englishPrompt(elementA, elementB));

    if (result.name !== null &&
        (typeof result.name !== "string" || typeof result.emoji !== "string")) {
      throw new Error("Malformed response from LLM");
    }

    // Profanity → store as "no combination" so it's never shown to anyone
    // and never re-asked from the LLM.
    if (result.name !== null && isBlocked(result.name)) {
      result.name = null;
      result.emoji = null;
    }

    const stored = await persistAndCanonicalize(
      lang,
      elementA,
      elementB,
      result,
      userId,
    );
    return jsonResponse(stored);
  } catch (error) {
    console.error("craft-element error:", error);
    const status = error instanceof LlmHttpError ? 502 : 500;
    return jsonResponse({ error: String(error) }, status);
  }
});
