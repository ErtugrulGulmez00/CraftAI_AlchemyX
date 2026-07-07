import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) notifications — currently just the opt-in daily
/// challenge reminder, toggled from Settings. No push backend involved.
class NotificationService {
  NotificationService._();

  static const _dailyReminderId = 1001;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensureInit() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  /// Schedules (or reschedules) the daily challenge reminder at 12:00 local
  /// time. Returns false if the user denied the notification permission, so
  /// the Settings toggle can bounce back off.
  ///
  /// Note on timezones: `tz.local` defaults to UTC, but converting a local
  /// [DateTime] instant preserves the correct moment for the first fire,
  /// and the daily repeat then keeps that wall-clock time. The only drift
  /// case is a DST change (the reminder shifts by an hour) — acceptable for
  /// a casual reminder, and avoids a whole extra timezone-lookup plugin.
  static Future<bool> enableDailyReminder({
    required String title,
    required String body,
  }) async {
    await _ensureInit();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) return false;

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 12);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      tz.TZDateTime.from(next, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_challenge',
          'Daily challenge',
          channelDescription:
              'Reminder when a new daily challenge word is ready',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact is fine for a reminder and avoids the Android 12+
      // SCHEDULE_EXACT_ALARM permission dance entirely.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return true;
  }

  static Future<void> disableDailyReminder() async {
    await _ensureInit();
    await _plugin.cancel(_dailyReminderId);
  }
}
