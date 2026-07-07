// Supabase Edge Function: delete-account
//
// In-app account deletion, required by Google Play policy (and KVKK/GDPR)
// for any app that offers sign-in. Deletes every row tied to the calling
// user, detaches their id from shared combination discoveries (the
// discoveries themselves stay — they're world data, not personal data),
// then removes the auth user itself.
//
// Auth: the caller's own JWT (must be a real, non-anonymous session).
// All writes use the service role.

import { createClient } from "npm:@supabase/supabase-js@2";

const service = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const COMBINATION_TABLES = [
  "combinations",
  "v2_combinations",
  "de_combinations",
  "es_combinations",
  "pt_combinations",
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const { data: userData } = await service.auth.getUser(token);
    const user = userData?.user;
    if (!user || user.is_anonymous) {
      return jsonResponse({ error: "sign-in required" }, 401);
    }
    const userId = user.id;

    // Personal data: delete outright.
    await service.from("user_progress").delete().eq("user_id", userId);
    await service.from("challenge_results").delete().eq("user_id", userId);
    await service.from("challenge_runs").delete().eq("user_id", userId);
    await service.from("combination_suggestions").delete().eq("suggested_by", userId);

    // Shared world data: keep the rows, drop the attribution (also clears
    // any FK to auth.users that would block the user delete below).
    for (const table of COMBINATION_TABLES) {
      try {
        await service.from(table)
          .update({ discovered_by: null })
          .eq("discovered_by", userId);
      } catch (_) {
        // Table may not exist yet in this environment — not fatal.
      }
    }

    const { error } = await service.auth.admin.deleteUser(userId);
    if (error) throw error;

    return jsonResponse({ ok: true });
  } catch (error) {
    console.error("delete-account error:", error);
    return jsonResponse({ error: String(error) }, 500);
  }
});
