# SÜPER ÖZET — CraftAI

> Projenin güncel durum özeti. (Temmuz 2026'da baştan yazıldı — eski, ~1000
> satırlık oturum-günlüğü versiyonunun yerine geçti.)

## Proje Nedir
Flutter ile yazılmış "Infinite Craft" tarzı sonsuz birleştirme oyunu.
Oyuncu iki elementi birleştirir, yapay zekâ yeni bir element üretir.
Paket adı `craftai`, görünen ad **CraftAI**, Android applicationId
`com.craftai.game`.

## Mimari — 3 Aşamalı $0 Combine Hattı (`CombinationService`)
1. **Hive local cache** (`LocalStorageService`) — anında, çevrimdışı çalışır.
2. **Supabase combine tabloları** (`SupabaseService.findCombination`) —
   dünyada daha önce keşfedilmiş her şey buradan gelir.
3. **`craft-element` Edge Function** → LLM (yalnızca dünyada ilk kez denenen
   çiftlerde): EN → Groq (llama-3.3-70b) → OpenRouter free pool fallback;
   TR2 → Groq → OpenRouter free → **Gemini (son çare)**; DE/ES/PT (beta) →
   OpenRouter paid küçük model. Function 502 = LLM upstream hatası, 500 =
   diğer. İstemci tarafında 3 denemeli retry var (`_withRetry`).

## Diller (GameLanguage)
`english` (öneksiz), `turkishV2` (`tr2:` pair_key, `v2_combinations`),
`german/spanish/portuguese` (beta). Her dil ayrı paralel oyun: ayrı Hive
kayıtları (`sessionSuffix`), ayrı Supabase tablosu, ayrı liderlik tablosu.
Eski Gemini-tabanlı `turkish` ("Türkçe Alt.", `tr:`) modülü **tamamen
kaldırıldı** (enum dahil). Supabase'te eski `tr:` satırları duruyor ama
hiçbir kod okumuyor.

## Oyun Modları
- **Simya Masası** (amber, `alchemytable` session) — tüp + havan tap
  mekaniği (`AlchemyTableBody`). Ana Oyun'a tıklayınca doğrudan oyun açılır
  (lobi ekranı yok).
- **Uzay Modu** (cyan, tek slot `'1'`) — sonsuz pan/zoom canvas'ta
  sürükle-bırak (`CraftCanvas`, uzaklaşınca "gezegen" görünümü). O da
  doğrudan açılır.
- Her iki ailenin içinde: **Hedef Mod** (kendi seçtiğin kelimeye ulaş,
  `target` session) ve **Yarışma Modu** (günün kelimesi + süre +
  Supabase liderlik tablosu, `challenge_<tarih>` session).
- Dünya sıfırlama oyun içindeki AppBar `restart_alt` butonunda.

## Supabase (proje ref: ggzvdnfiiyrmqzcpysbz, Frankfurt)
- Tablolar: `combinations`, `v2_combinations`, `de/es/pt_combinations`,
  `challenge_results`, `combination_suggestions`, `user_progress`.
  RLS hepsi açık; referans SQL'ler `supabase/sql/` altında.
- Herkes anonim oturum alır (`signInAnonymously`); Google OAuth ile gerçek
  hesap (`AuthProvider`, redirect: `io.supabase.mimecraft://login-callback`).
- **Bulut yedek**: gerçek kullanıcının keşifleri `user_progress`'e yazılır
  (`upsertProgress`, fire-and-forget) ve girişte sessizce geri yüklenir
  (additive merge). Not: yerel dünya sıfırlama bulut satırlarını silmez.
- **Topluluk önerileri** (EN+TR2): kullanıcı "A+B=C" önerir, admin
  (`AppConstants.adminUserId`, RLS'te de gömülü) onaylarsa ilgili tablonun
  o pair_key satırı override edilir.
- **Admin**: `adminUserId` sadece kozmetik istemci kontrolü; gerçek yetki
  RLS'te.

## Öne Çıkan Özellikler
- **Günlük görevler** (`DailyQuestService`, global `daily_quests` Hive
  kutusu): günlük birleştirme/keşif sayaçları, Stats sekmesinde 3 görev.
- **Keşif paylaşımı** (`ShareService` + share_plus): ilk keşif anında
  Canvas ile çizilen 1080x1080 kozmik kart + paylaşım metni.
- **Günlük yarışma bildirimi** (`NotificationService` +
  flutter_local_notifications): Ayarlar'dan opt-in, her gün ~12:00.
- **Element ansiklopedisi**: Keşifler'de elemente uzun bas (tüp modlarında
  tek dokunuş) → o elementi üreten yerel tarifler sheet'i.
- **Favoriler**: tepside uzun bas → yıldız; filtre toggle'ı.
- Çevrimdışı/beklenmedik combine hataları lokalize mesajlarla gösterilir
  (`GameProvider._combineErrorMessage`); ham exception asla gösterilmez.

## Görsel Kimlik
Tüm oyun/menü ekranları koyu "kozmik lab" teması (`CosmicBackground`:
`0xFF0B0916` taban + accent nebula + sabit-seed yıldızlar; uygulama
temasından bağımsız hep koyu). Accent'ler: Simya=amber `0xFFFFA53D`,
Uzay=cyan `0xFF4FD1E8`, Hedef=turuncu, Yarışma=altın. Oyna sekmesi:
Lottie robot maskot (`assets/robot.json`) + metalik "CraftAI" + 2 neon kart
+ gerçek Google SVG'li giriş butonu. Alt nav: 3 emoji'li parlayan chip
(İstatistik / Oyna [ortada, açılış sekmesi] / Ayarlar).

## Güvenlik Sertleştirmesi (Temmuz 2026 denetimi — UYGULANDI)
1. ✅ Release imzalama: `android/keystore/craftai-release.jks` +
   `android/key.properties` (ASLA paylaşma/silme — kaybı, uygulamayı bir
   daha güncelleyememek demek). applicationId → **com.craftai.game**.
2. ✅ Combine yazmaları edge function'a taşındı (service role); istemci
   insert policy'leri `craft_hardening.sql` ile düşürülür.
3. ✅ Yarışma süresi sunucuda: `challenge_runs` + `finish_challenge` RPC
   (`challenge_server_timing.sql`); display_name de auth kaydından gelir.
4. ✅ Rate limit: kullanıcı başına 12 craft/dk (`bump_craft_rate`).
5. ✅ Hesap silme: Ayarlar → Tehlike bölgesi → "Hesabımı sil" →
   `delete-account` edge function (kişisel satırlar + auth kaydı).
6. ✅ Dünya sıfırlama artık ilgili `user_progress` satırlarını da siler.
7. ✅ Hive statik yardımcıları açık box'ı kapatmaz (`isBoxOpen` guard).
8. ✅ Emoji filtresi pictograph-tabanlı; edge function'da hafif küfür
   kara listesi (engellenen sonuç "no combination" olarak saklanır).
Kalan bilinçli riskler: eski 2/3 Uzay dünyaları ve `_tr` kayıtları diskte
yetim; DST değişiminde bildirim saati 1 saat kayabilir.

> **Yeni kurulumda kullanıcı adımı:** `craft_hardening.sql` ve
> `challenge_server_timing.sql` Supabase SQL Editor'de bir kez çalıştırılmalı
> (rate limit + policy düşürme + challenge_runs bunlarsız devreye girmez).

## Geliştirme Akışı
`flutter analyze lib/` → `dart format lib/` → `flutter run -d <cihaz>
--release` (kablosuz adb; cihaz kimliği sık değişir, `adb devices -l` ile
kontrol et). Edge function deploy: `supabase functions deploy craft-element`.
