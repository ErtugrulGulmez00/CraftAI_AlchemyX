/// Lightweight, globally-readable runtime flags for cross-cutting
/// preferences (sound, haptics) that low-level services need without
/// depending on the widget tree / Provider.
///
/// [SettingsProvider] is the source of truth: it loads these from Hive
/// and mirrors every change here so [SoundService] and [GameProvider]
/// can read them statically.
class GameSettings {
  GameSettings._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;
}
