import '../../models/element_model.dart';
import 'game_language.dart';

class AppConstants {
  AppConstants._();

  static const String supabaseUrl = 'https://ggzvdnfiiyrmqzcpysbz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdnenZkbmZpaXlybXF6Y3B5c2J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0NTc5NzUsImV4cCI6MjA5NzAzMzk3NX0.CuecR6RxdbtDGrPCuUiLnfdtLcHBZEBXXaWo2cmDGc4';

  static const String craftEdgeFunction = 'craft-element';

  /// Supabase combination tables — one per language namespace.
  static const String combinationsTable = 'combinations';
  static const String combinationsTableTr2 = 'v2_combinations';
  static const String combinationsTableDe = 'de_combinations';
  static const String combinationsTableEs = 'es_combinations';
  static const String combinationsTablePt = 'pt_combinations';

  static const String challengeResultsTable = 'challenge_results';
  static const String combinationSuggestionsTable = 'combination_suggestions';
  static const String userProgressTable = 'user_progress';

  static const String adminUserId = 'edabc320-2a65-453d-bdb5-343758d00a33';

  static const String oauthRedirectUrl =
      'io.supabase.mimecraft://login-callback';

  static const String appVersion = '1.0.1';

  // Space Mode used to offer 3 parallel save-slots ('1', '2', '3'); reduced
  // to a single slot so "Ana Oyun" can jump straight into gameplay with no
  // world-picker screen in between (fewer taps to start playing).
  static const List<String> sessionIds = ['1'];

  /// Single-slot modes whose discoveries should also count toward the Stats
  /// tab's totals/badges/per-language breakdown, alongside the numbered
  /// Space Mode slots above. Challenge Mode is intentionally excluded: its
  /// session id rotates daily (`challenge_<date>`), so it would require
  /// enumerating Hive box names rather than a fixed list.
  static const List<String> extraStatSessionIds = ['alchemytable', 'target'];

  static String discoveredElementsBox(String sessionId) =>
      'discovered_elements_$sessionId';

  static String combinationsCacheBox(String sessionId) =>
      'combinations_cache_$sessionId';

  static String favoritesBox(String sessionId) =>
      'favorite_elements_$sessionId';

  static String sessionKey(String baseId, GameLanguage language) =>
      '$baseId${language.sessionSuffix}';

  static List<GameElement> get startingElements => [
    GameElement(name: 'Water', emoji: '💧'),
    GameElement(name: 'Fire', emoji: '🔥'),
    GameElement(name: 'Wind', emoji: '🌬️'),
    GameElement(name: 'Earth', emoji: '🌍'),
  ];

  static List<GameElement> get startingElementsTr => [
    GameElement(name: 'Su', emoji: '💧'),
    GameElement(name: 'Ateş', emoji: '🔥'),
    GameElement(name: 'Hava', emoji: '🌬️'),
    GameElement(name: 'Toprak', emoji: '🌍'),
  ];

  static List<GameElement> get startingElementsDe => [
    GameElement(name: 'Wasser', emoji: '💧'),
    GameElement(name: 'Feuer', emoji: '🔥'),
    GameElement(name: 'Wind', emoji: '🌬️'),
    GameElement(name: 'Erde', emoji: '🌍'),
  ];

  static List<GameElement> get startingElementsEs => [
    GameElement(name: 'Agua', emoji: '💧'),
    GameElement(name: 'Fuego', emoji: '🔥'),
    GameElement(name: 'Viento', emoji: '🌬️'),
    GameElement(name: 'Tierra', emoji: '🌍'),
  ];

  static List<GameElement> get startingElementsPt => [
    GameElement(name: 'Água', emoji: '💧'),
    GameElement(name: 'Fogo', emoji: '🔥'),
    GameElement(name: 'Vento', emoji: '🌬️'),
    GameElement(name: 'Terra', emoji: '🌍'),
  ];

  static List<GameElement> startingElementsFor(GameLanguage language) =>
      switch (language) {
        GameLanguage.english => startingElements,
        GameLanguage.turkishV2 => startingElementsTr,
        GameLanguage.german => startingElementsDe,
        GameLanguage.spanish => startingElementsEs,
        GameLanguage.portuguese => startingElementsPt,
      };
}
