# Dosya Yapısı — CraftAI

> Güncel klasör/dosya haritası (Temmuz 2026'da baştan yazıldı).

```
WordCraftInf/
├── superozet.md              # Proje durumu özeti
├── dosyayapisi.md            # Bu dosya
├── pubspec.yaml              # provider, supabase_flutter, hive(+flutter),
│                             # audioplayers, vibration, lottie, flutter_svg,
│                             # share_plus, flutter_local_notifications, timezone
├── assets/
│   ├── sounds/               # pop/discovery/error.wav (tool ile sentezlendi)
│   ├── robot.json            # Oyna sekmesindeki Lottie maskot
│   ├── google_logo.svg       # Resmi 4 renkli Google "G" (giriş butonları)
│   ├── icon/                 # Launcher ikonu PNG'leri (üreticisi: test/)
│   └── fonts/                # Nunito 400/600/700/800
│
├── android/
│   ├── key.properties        # Release imza şifreleri (YEDEKLE, paylaşma)
│   └── keystore/craftai-release.jks  # Release keystore (YEDEKLE)
│
├── test/
│   └── generate_icon_test.dart # Launcher ikonunu Canvas ile çizip PNG basar
│                             # (flutter test ile çalıştır + flutter_launcher_icons)
│
├── tool/
│   └── generate_sounds.dart  # WAV'ları sinüs dalgasından üreten betik
│
├── supabase/
│   ├── config.toml           # supabase CLI yerel config
│   ├── functions/
│   │   ├── craft-element/index.ts
│   │   │    # Stage 3 LLM edge function (v2): sonucu service role ile
│   │   │    # kendisi yazar, kullanıcı başına rate limit + küfür filtresi.
│   │   │    # EN: Groq→OpenRouter free. TR2: +Gemini son çare.
│   │   │    # DE/ES/PT: OpenRouter paid. 502=LLM hatası, 429=rate limit.
│   │   └── delete-account/index.ts
│   │        # Google Play zorunlu hesap silme: kişisel satırlar + auth kaydı.
│   └── sql/                  # Referans SQL'ler (SQL Editor'de elle çalıştırılır)
│       ├── challenge_mode.sql            # challenge_results + RLS
│       ├── challenge_server_timing.sql   # challenge_runs + finish_challenge RPC
│       ├── combination_suggestions.sql   # öneriler + admin override policy'leri
│       ├── craft_hardening.sql           # rate limit + insert policy düşürme
│       └── user_progress.sql             # bulut ilerleme yedeği + RLS
│
└── lib/
    ├── main.dart             # Hive+Supabase init → MultiProvider → SplashView
    │
    ├── core/
    │   ├── constants/
    │   │   ├── app_constants.dart    # Supabase url/key, tablo adları, adminUserId,
    │   │   │                         # session id'leri, başlangıç elementleri (5 dil)
    │   │   ├── game_language.dart    # GameLanguage enum (en/tr2/de/es/pt) + code/
    │   │   │                         # sessionSuffix/nativeName/flag/accentColor
    │   │   └── word_bank.dart        # Hedef/Yarışma kelime bankaları (5 dil),
    │   │                             # todaysChallengeWord(), todayDateKey()
    │   ├── localization/
    │   │   └── app_strings.dart      # AppStringsData: tüm UI metinleri, 5 dil
    │   ├── theme/app_theme.dart      # AppPalette + light/dark ThemeData (Nunito)
    │   ├── utils/combination_key.dart# Sıra-bağımsız, dil-önekli pair_key üretimi
    │   ├── haptics.dart              # Titreşim yardımcıları (GameSettings'e bakar)
    │   ├── game_settings.dart        # Ses/titreşim için global statik bayraklar
    │   └── services/
    │       ├── local_storage_service.dart  # Hive: elementler, combine cache,
    │       │                               # favoriler, tarifler (getRecipesFor),
    │       │                               # sayaçlar, reset, bulut merge
    │       ├── supabase_service.dart       # Stage 2+3, liderlik, öneriler,
    │       │                               # user_progress yedek/geri yükleme
    │       ├── combination_service.dart    # 3 aşamalı combine + retry + günlük
    │       │                               # görev sayaçları + bulut yedek hook'u
    │       ├── daily_quest_service.dart    # Günlük birleştirme/keşif sayaçları
    │       ├── share_service.dart          # 1080x1080 keşif kartı çiz + paylaş
    │       ├── notification_service.dart   # Günlük yarışma hatırlatıcısı (yerel)
    │       └── sound_service.dart          # audioplayers ile 3 efekt
    │
    ├── models/
    │   ├── element_model.dart        # GameElement (Hive tipi, key=lowercase ad)
    │   └── element_model.g.dart      # build_runner çıktısı adapter
    │
    ├── providers/
    │   ├── settings_provider.dart    # Tema/ses/titreşim/dil/hatırlatıcı (Hive)
    │   ├── auth_provider.dart        # Anonim/Google oturum + girişte bulut restore
    │   └── game_provider.dart        # Canvas item'ları, combine akışı, favoriler,
    │                                 # sıralama, lokalize hata mesajları
    │
    ├── views/
    │   ├── splash_view.dart          # Animasyonlu açılış → Onboarding/MainShell
    │   ├── onboarding_view.dart      # 5 sayfalık ilk kurulum (dil seçimi dahil)
    │   ├── main_shell.dart           # Kök shell: 3 sekmeli özel kozmik nav bar
    │   ├── worlds_view.dart          # "Oyna" sekmesi: maskot + 2 mod ailesi kartı
    │   ├── mode_family_hub_view.dart # Aile hub'ı: Ana Oyun / Hedef / Yarışma
    │   ├── free_mode_view.dart       # Uzay Ana Oyun: doğrudan oyunu açan loader
    │   ├── alchemy_table_mode_view.dart # Simya Ana Oyun: aynı loader deseni
    │   ├── game_screen.dart          # Uzay Modu oyun ekranı (canvas + paylaş)
    │   ├── alchemy_table_game_screen.dart # Simya oyun ekranı (tüp+havan)
    │   ├── target_mode_view.dart     # Hedef Mod lobisi (kelime seç)
    │   ├── target_mode_game_screen.dart   # Hedef Mod oyunu (canvas veya tüp)
    │   ├── challenge_mode_view.dart  # Yarışma lobisi + liderlik tablosu
    │   ├── challenge_game_screen.dart# Yarışma oyunu (süre + skor gönderimi)
    │   ├── craft_view.dart           # Canvas + yatay element tepsisi düzeni
    │   ├── discoveries_view.dart     # Keşifler: arama + grid + tarif sheet'i
    │   ├── stats_view.dart           # İstatistik: toplamlar, günlük görevler,
    │   │                             # rozetler, dil bazlı döküm
    │   ├── settings_view.dart        # Ayarlar: hesap, görünüm, dil, bildirim,
    │   │                             # topluluk önerileri, sıfırlama
    │   ├── combination_suggestions_view.dart # "A+B=C" öner (EN+TR2)
    │   └── combination_review_view.dart      # Admin onay ekranı
    │
    └── widgets/
        ├── cosmic_background.dart    # Paylaşılan koyu nebula+yıldız arka planı
        ├── alchemy_table_body.dart   # Tüp+havan sahnesi, tepsi, favoriler,
        │                             # ilk keşif banner'ı (+paylaş), dekorlar
        ├── craft_canvas.dart         # Sonsuz pan/zoom canvas + gezegen görünümü
        ├── globe_background.dart     # Uzaklaşınca görünen küre/yıldız painter'ı
        ├── element_card.dart         # Ortak element kartı görünümü
        ├── confetti_overlay.dart     # İlk keşif konfeti patlaması
        ├── merge_particles.dart      # Birleşme parçacık efekti
        ├── leaderboard_list.dart     # Yarışma liderlik listesi
        └── animated_section_widgets.dart # Stagger/SectionHeading/HeroCard
```

Not: Temmuz 2026 temizliğinde kullanım dışı kalan dosyalar (login_view,
element_grid, tüm Türkçe seed betikleri/SQL'leri) silindi; listedeki her
dosya canlı olarak kullanılıyor.
