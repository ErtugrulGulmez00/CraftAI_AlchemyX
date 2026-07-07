import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/game_language.dart';
import '../core/game_settings.dart';

/// App-wide preferences (theme, sound, haptics), persisted to a single
/// global Hive box shared across every world/save-slot.
///
/// Besides notifying the UI, it mirrors sound/haptics into [GameSettings]
/// so low-level services can read them without a [BuildContext].
class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _darkModeKey = 'darkMode';
  static const String _soundKey = 'soundEnabled';
  static const String _hapticsKey = 'hapticsEnabled';
  static const String _seenWelcomeKey = 'hasSeenWelcome';
  static const String _languageKey = 'gameLanguage';
  static const String _dailyReminderKey = 'dailyReminderEnabled';

  ThemeMode _mode = ThemeMode.light;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _hasSeenWelcome = false;
  bool _dailyReminderEnabled = false;
  GameLanguage _language = GameLanguage.english;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  /// Whether the user has already passed the initial login/guest screen.
  bool get hasSeenWelcome => _hasSeenWelcome;

  /// Whether the daily challenge reminder notification is scheduled.
  bool get dailyReminderEnabled => _dailyReminderEnabled;

  /// The active game language. Switching this is a "parallel game" - see
  /// [GameLanguage.sessionSuffix].
  GameLanguage get language => _language;

  SettingsProvider() {
    _load();
  }

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<void> _load() async {
    final box = await _box();
    _mode = (box.get(_darkModeKey, defaultValue: false) as bool)
        ? ThemeMode.dark
        : ThemeMode.light;
    _soundEnabled = box.get(_soundKey, defaultValue: true) as bool;
    _hapticsEnabled = box.get(_hapticsKey, defaultValue: true) as bool;
    _hasSeenWelcome = box.get(_seenWelcomeKey, defaultValue: false) as bool;
    _dailyReminderEnabled =
        box.get(_dailyReminderKey, defaultValue: false) as bool;
    _language = switch (box.get(_languageKey, defaultValue: 'en') as String) {
      'tr2' => GameLanguage.turkishV2,
      'de' => GameLanguage.german,
      'es' => GameLanguage.spanish,
      'pt' => GameLanguage.portuguese,
      _ => GameLanguage.english,
    };

    GameSettings.soundEnabled = _soundEnabled;
    GameSettings.hapticsEnabled = _hapticsEnabled;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _mode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    (await _box()).put(_darkModeKey, value);
  }

  Future<void> setSound(bool value) async {
    _soundEnabled = value;
    GameSettings.soundEnabled = value;
    notifyListeners();
    (await _box()).put(_soundKey, value);
  }

  Future<void> setHaptics(bool value) async {
    _hapticsEnabled = value;
    GameSettings.hapticsEnabled = value;
    notifyListeners();
    (await _box()).put(_hapticsKey, value);
  }

  /// Persists the reminder preference. Actually scheduling/cancelling the
  /// notification is the caller's job (see NotificationService) — it needs
  /// localized strings and a permission prompt this provider shouldn't own.
  Future<void> setDailyReminder(bool value) async {
    if (_dailyReminderEnabled == value) return;
    _dailyReminderEnabled = value;
    notifyListeners();
    (await _box()).put(_dailyReminderKey, value);
  }

  Future<void> setSeenWelcome(bool value) async {
    if (_hasSeenWelcome == value) return;
    _hasSeenWelcome = value;
    notifyListeners();
    (await _box()).put(_seenWelcomeKey, value);
  }

  Future<void> setLanguage(GameLanguage value) async {
    if (_language == value) return;
    _language = value;
    notifyListeners();
    (await _box()).put(_languageKey, value.code);
  }
}
