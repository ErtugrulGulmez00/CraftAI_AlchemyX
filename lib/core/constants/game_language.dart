import 'package:flutter/material.dart';

/// The supported game languages. Switching language in Settings is a
/// "parallel game" - separate worlds, discoveries, and challenge state - but
/// shares the same codebase and Supabase backend.
enum GameLanguage {
  english,
  turkishV2,
  german,
  spanish,
  portuguese;

  /// Code sent to the `craft-element` Edge Function and used as the
  /// `pair_key`/`challenge_results.language` discriminator.
  String get code => switch (this) {
    GameLanguage.english => 'en',
    GameLanguage.turkishV2 => 'tr2',
    GameLanguage.german => 'de',
    GameLanguage.spanish => 'es',
    GameLanguage.portuguese => 'pt',
  };

  /// Suffix appended to Hive sessionIds. Empty for English so existing
  /// session boxes (`1`, `2`, `3`, `target`, `challenge_...`) and
  /// `combinations` pair_keys keep working unchanged.
  String get sessionSuffix => switch (this) {
    GameLanguage.english => '',
    GameLanguage.turkishV2 => '_tr2',
    GameLanguage.german => '_de',
    GameLanguage.spanish => '_es',
    GameLanguage.portuguese => '_pt',
  };

  /// Name shown in-app for this language, in its own language.
  String get nativeName => switch (this) {
    GameLanguage.english => 'English',
    GameLanguage.turkishV2 => 'Türkçe',
    GameLanguage.german => 'Deutsch',
    GameLanguage.spanish => 'Español',
    GameLanguage.portuguese => 'Português',
  };

  /// Flag emoji shown next to [nativeName] in language-aware UI.
  String get flag => switch (this) {
    GameLanguage.english => '🇬🇧',
    GameLanguage.turkishV2 => '🇹🇷',
    GameLanguage.german => '🇩🇪',
    GameLanguage.spanish => '🇪🇸',
    GameLanguage.portuguese => '🇧🇷',
  };

  /// A distinct accent color per language, used to give each language's
  /// section its own visual identity (e.g. in the Stats tab).
  Color get accentColor => switch (this) {
    GameLanguage.english => const Color(0xFF3B82F6),
    GameLanguage.turkishV2 => const Color(0xFFEF4444),
    GameLanguage.german => const Color(0xFFF59E0B),
    GameLanguage.spanish => const Color(0xFFF97316),
    GameLanguage.portuguese => const Color(0xFF22C55E),
  };

  /// Reverse of [code] — turns a stored language code back into its enum
  /// value (e.g. when reading a `language` column back from Supabase).
  static GameLanguage fromCode(String code) => switch (code) {
    'tr2' => GameLanguage.turkishV2,
    'de' => GameLanguage.german,
    'es' => GameLanguage.spanish,
    'pt' => GameLanguage.portuguese,
    _ => GameLanguage.english,
  };

  /// Languages actively surfaced to players.
  static const active = [
    GameLanguage.english,
    GameLanguage.turkishV2,
    GameLanguage.german,
    GameLanguage.spanish,
    GameLanguage.portuguese,
  ];
}
