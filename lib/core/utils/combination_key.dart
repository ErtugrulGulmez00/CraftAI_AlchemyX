import '../constants/game_language.dart';

/// Builds a stable, order-independent cache/DB key for an element pair.
///
/// Combinations are normalized by sorting the two element names
/// alphabetically before joining them, with a language prefix so keys
/// never collide across language tables.
/// English keys are unprefixed to keep existing discoveries valid.
String combinationKey(String elementA, String elementB, GameLanguage language) {
  final a = elementA.toLowerCase().trim();
  final b = elementB.toLowerCase().trim();
  final sorted = [a, b]..sort();
  final key = '${sorted[0]}+${sorted[1]}';
  return switch (language) {
    GameLanguage.english => key,
    GameLanguage.turkishV2 => 'tr2:$key',
    GameLanguage.german => 'de:$key',
    GameLanguage.spanish => 'es:$key',
    GameLanguage.portuguese => 'pt:$key',
  };
}
