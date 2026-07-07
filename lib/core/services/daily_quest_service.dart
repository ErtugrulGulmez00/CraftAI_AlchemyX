import 'package:hive_flutter/hive_flutter.dart';

/// Tracks small per-day counters (combine attempts, newly-discovered
/// elements) across every mode/session, backing the "Daily quests" section
/// on the Stats tab.
///
/// One global Hive box; keys are `YYYY-MM-DD_<counter>` so past days simply
/// stop being read — at a few ints per day no cleanup is ever needed. The
/// box is opened lazily and kept open (it's global, so the close-under-a-
/// live-session hazard of per-session boxes doesn't apply).
class DailyQuestService {
  DailyQuestService._();

  static const _boxName = 'daily_quests';
  static Box<int>? _box;

  static Future<Box<int>> _open() async =>
      _box ??= await Hive.openBox<int>(_boxName);

  static String _todayKey(String counter) {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-${day}_$counter';
  }

  /// Any combine attempt, successful or not — "keep playing" quests.
  static Future<void> recordCombine() async {
    final box = await _open();
    final key = _todayKey('combines');
    await box.put(key, (box.get(key) ?? 0) + 1);
  }

  /// A combine that produced an element this device hadn't seen before.
  static Future<void> recordDiscovery() async {
    final box = await _open();
    final key = _todayKey('discoveries');
    await box.put(key, (box.get(key) ?? 0) + 1);
  }

  /// Today's counters: (combine attempts, new discoveries).
  static Future<(int combines, int discoveries)> today() async {
    final box = await _open();
    return (
      box.get(_todayKey('combines')) ?? 0,
      box.get(_todayKey('discoveries')) ?? 0,
    );
  }
}
