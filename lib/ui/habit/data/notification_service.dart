import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'habit.dart';
import 'settings_storage.dart';

/// Schedules the daily/weekly habit reminders configured on the
/// Notifications screen, using `flutter_local_notifications`.
///
/// Design:
///  * One notification per reminder day (not per habit), listing the chosen
///    habits in the body. That keeps the pending count tiny (1 / 5 / 2),
///    well under iOS's 64-notification limit, and avoids a stack of
///    identical notifications at the same minute.
///  * [sync] always cancels this service's ids first and re-creates them, so
///    it's safe to call whenever settings, habits or the time zone change.
///  * Only Android, iOS and macOS are wired up. On other platforms (web,
///    desktop) every method is a harmless no-op.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit reminders';
  static const _channelDescription =
      'Daily nudges to check off your habits.';

  /// Notification ids 4200..4207 belong to this service.
  /// 4200 = every day, 4201..4207 = Monday..Sunday (DateTime.weekday).
  static const _idBase = 4200;
  static const _testId = 4299;

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _ready = false;
  String? _timeZoneName;
  Future<void> _queue = Future.value();

  bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// IANA name of the device time zone (e.g. "Asia/Ho_Chi_Minh"), once
  /// [init] has run. Null if it couldn't be determined.
  String? get timeZoneName => _timeZoneName;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  // ----------------------------------------------------------------- Init

  /// Call once at startup (before `runApp`). Safe to call repeatedly.
  Future<void> init() async {
    if (_ready || !_supported) return;

    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();

    // Permission prompts are deferred to [requestPermission] so the user
    // isn't asked before they've turned reminders on.
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
      // Tapping a reminder just opens the app on the Home screen.
    );
    _ready = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _timeZoneName = info.identifier;
    } catch (e) {
      debugPrint('NotificationService: could not read time zone ($e).');
      // Fallback: pick a zone whose current offset matches the device's.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.timeZone(nowMs).offset == offsetMs) {
          tz.setLocalLocation(location);
          _timeZoneName = location.name;
          return;
        }
      }
    }
  }

  // ----------------------------------------------------------- Permission

  /// Asks the OS for permission to show notifications (and, on Android, to
  /// schedule exact alarms). Returns whether notifications are allowed.
  /// Call this from a user action, e.g. when they save with reminders on.
  Future<bool> requestPermission() async {
    if (!_supported) return true;
    await init();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _android;
        if (android == null) return false;
        final granted = await android.requestNotificationsPermission() ?? true;
        if (granted && !(await android.canScheduleExactNotifications() ?? false)) {
          // Opens the system "Alarms & reminders" page on Android 12+.
          // If the user declines, reminders fall back to inexact timing.
          await android.requestExactAlarmsPermission();
        }
        return granted;
      case TargetPlatform.iOS:
        return await _plugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      case TargetPlatform.macOS:
        return await _plugin
            .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      default:
        return true;
    }
  }

  // ----------------------------------------------------------------- Sync

  /// Replaces all scheduled reminders with ones matching [settings].
  /// Calls are queued so overlapping syncs can't interleave.
  Future<void> sync(NotificationSettings settings, List<Habit> habits) {
    return _queue = _queue.then((_) => _sync(settings, habits)).catchError(
          (Object e, StackTrace s) {
        debugPrint('NotificationService.sync failed: $e');
      },
    );
  }

  /// Convenience for app start / habit changes: reads the saved settings for
  /// [username] and syncs them against [habits].
  Future<void> syncForUser(String username, List<Habit> habits) async {
    final settings = await SettingsStorage(username).readNotifications();
    await sync(settings, habits);
  }

  /// Removes every reminder this service has scheduled (e.g. on log out).
  Future<void> cancelReminders() {
    return _queue = _queue.then((_) => _cancelAll()).catchError(
          (Object e, StackTrace s) {
        debugPrint('NotificationService.cancelReminders failed: $e');
      },
    );
  }

  Future<void> _cancelAll() async {
    if (!_supported) return;
    await init();
    for (var id = _idBase; id <= _idBase + 7; id++) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> _sync(NotificationSettings settings, List<Habit> habits) async {
    if (!_supported) return;
    await init();
    await _cancelAll();

    if (!settings.enabled) return;

    // Only habits that still exist, in the order shown on Home.
    final names = [
      for (final h in habits)
        if (settings.habitIds.contains(h.id)) h.name,
    ];
    if (names.isEmpty) return;

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
      ),
    );
    final mode = await _androidScheduleMode();
    final body = _body(names);

    switch (settings.repeat) {
      case RepeatRule.everyDay:
        await _schedule(
          id: _idBase,
          body: body,
          when: _nextInstance(settings.hour, settings.minute),
          details: details,
          mode: mode,
          match: DateTimeComponents.time,
        );
      case RepeatRule.weekdays:
        for (var d = DateTime.monday; d <= DateTime.friday; d++) {
          await _scheduleWeekly(d, settings, body, details, mode);
        }
      case RepeatRule.weekends:
        await _scheduleWeekly(DateTime.saturday, settings, body, details, mode);
        await _scheduleWeekly(DateTime.sunday, settings, body, details, mode);
    }
  }

  Future<void> _scheduleWeekly(
      int weekday,
      NotificationSettings settings,
      String body,
      NotificationDetails details,
      AndroidScheduleMode mode,
      ) {
    return _schedule(
      id: _idBase + weekday,
      body: body,
      when: _nextInstance(settings.hour, settings.minute, weekday: weekday),
      details: details,
      mode: mode,
      match: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> _schedule({
    required int id,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required AndroidScheduleMode mode,
    required DateTimeComponents match,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: 'Habit reminder',
      body: body,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: match,
    );
  }

  /// Exact timing when the user allowed exact alarms, otherwise inexact
  /// (may be delayed by a few minutes, but still fires).
  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.exactAllowWhileIdle; // ignored off Android
    }
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Next wall-clock occurrence of [hour]:[minute] (on [weekday] if given),
  /// built field-by-field so DST changes don't shift the time.
  tz.TZDateTime _nextInstance(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (candidate.isBefore(now) ||
        (weekday != null && candidate.weekday != weekday)) {
      candidate = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day + 1,
        hour,
        minute,
      );
    }
    return candidate;
  }

  String _body(List<String> names) {
    if (names.length <= 3) return 'Time to check in: ${names.join(', ')}';
    final rest = names.length - 2;
    return 'Time to check in: ${names.take(2).join(', ')} and $rest more';
  }

  // ----------------------------------------------------------------- Test

  /// Shows a notification immediately. Handy for checking permissions and
  /// the Android channel without waiting for the scheduled time.
  Future<void> showTestNotification() async {
    if (!_supported) return;
    await init();
    await _plugin.show(
      id: _testId,
      title: 'Habit reminder',
      body: 'Reminders are working.',
      notificationDetails: NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
    );
  }
}