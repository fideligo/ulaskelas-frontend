// Local QA harness for the notification stack, usable without a backend
// scheduler or an FCM send. Layers 2 and 3 produce real OS notifications
// carrying the real payload, so they enter the app through the same callbacks
// as a production push; only the transport differs.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:ulaskelas/services/notification/_notification.dart';
import 'package:ulaskelas/services/notification/routing/notification_router.dart';

abstract class DevNotificationSimulator {
  static bool _timezoneReady = false;

  /// Console prefix so the Layer 3 diagnostics can be grepped out of the noisy
  /// Flutter log with a single filter.
  static const String _tag = '[DEV SIM]';

  /// Kept outside [LocalNotificationClient]'s hash-derived id range so that a
  /// scheduled test never replaces a real notification.
  static const int _scheduleId = 990001;

  /// Layer 1: dispatches straight into the router, bypassing the tray.
  /// Verifies tab switching and course hydration.
  static Future<void> route(NotificationPayload payload) {
    return NotificationRouter.handle(payload);
  }

  /// Layer 2: posts a real tray notification carrying the real JSON payload.
  /// Tapping it exercises the same callback path as a production push.
  static Future<void> fire(NotificationPayload payload) async {
    await _requireNotificationsEnabled();
    await BadgeService.increment();
    await LocalNotificationClient.show(payload);
  }

  /// Layer 3: stands in for the Friday 16:00 and end-of-month cron jobs.
  ///
  /// To exercise the terminated state, schedule a notification, swipe the app
  /// away from the recents switcher, then tap it. This is the only reliable way
  /// to cover `getNotificationAppLaunchDetails` and the parked-payload replay.
  ///
  /// Swipe it away — do not use Settings > Force stop. A force stop cancels
  /// every alarm the app owns, so the notification silently never arrives and
  /// the run looks like the scheduling bug it is being used to rule out.
  static Future<void> schedule(
    NotificationPayload payload, {
    Duration after = const Duration(seconds: 15),
  }) async {
    _ensureTimezone();
    final scheduledDate = tz.TZDateTime.now(tz.local).add(after);
    await _preflight(scheduledDate);

    await LocalNotificationClient.plugin.zonedSchedule(
      _scheduleId,
      payload.title ?? '[DEV] ${payload.type}',
      payload.body ?? 'Dijadwalkan ${after.inSeconds} detik yang lalu.',
      scheduledDate,
      NotificationChannels.details,
      payload: payload.toJsonString(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // AlarmManager buckets inexact alarms into maintenance windows from API
      // 31 onward, which defers a 15-second QA alarm by 10+ minutes on an idle
      // emulator, or indefinitely. alarmClock is the only mode exempt from both
      // Doze deferral and the ~9-minute rate limit that throttles repeated
      // setExactAndAllowWhileIdle calls, so a tester can fire it back to back.
      // The exact-alarm permission it needs is declared in src/debug only, so
      // production never ships it.
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );

    // If _scheduleId is absent here, AlarmManager never accepted the alarm and
    // no amount of waiting will produce a notification. This is the single
    // check that separates "never scheduled" from "scheduled but not fired".
    final pending =
        await LocalNotificationClient.plugin.pendingNotificationRequests();
    print('$_tag pending ids: ${pending.map((r) => r.id).toList()}');
    if (pending.every((r) => r.id != _scheduleId)) {
      throw StateError(
        'AlarmManager tidak menerima alarm $_scheduleId. Masalahnya ada di '
        'penjadwalan, bukan di penayangan notifikasi.',
      );
    }
  }

  /// Both layers post through `NotificationManager`, which drops every message
  /// from an app without `POST_NOTIFICATIONS` and reports nothing when it does.
  /// Layer 3 hides that even better than Layer 2: `zonedSchedule` returns
  /// normally, AlarmManager accepts and fires the alarm on time, and the drop
  /// then happens inside a broadcast receiver that has no Dart engine attached,
  /// so it cannot reach the console at all. Refusing to post is what turns that
  /// into something a tester can see.
  static Future<void> _requireNotificationsEnabled() async {
    final enabled = await _android?.areNotificationsEnabled();
    print('$_tag notifsEnabled : $enabled');
    // Null on iOS, where this resolver has no implementation to return.
    if (enabled ?? true) return;

    // The consent sheet is one-shot per install: once denied twice, Android
    // returns without showing anything, so Settings is the only way back.
    print('$_tag POST_NOTIFICATIONS denied - requesting');
    if (await NotificationPermission.request()) return;

    throw StateError(
      'POST_NOTIFICATIONS ditolak. Alarm tetap menyala, tetapi sistem '
      'membuang notifikasinya tanpa error. Aktifkan lewat Settings > Apps > '
      'TemanKuliah > Notifications, lalu coba lagi.',
    );
  }

  /// The scheduled path can fail in ways the tray path cannot: exact alarms are
  /// permission-gated from API 31, and the plugin raises that from native code
  /// without writing anything to the Dart console. Printing the resolved
  /// instant and the permission state is what makes those distinguishable.
  static Future<void> _preflight(tz.TZDateTime scheduledDate) async {
    print('$_tag target (tz)   : $scheduledDate');
    print('$_tag zone name     : ${scheduledDate.location.name}');
    print('$_tag target (local): ${scheduledDate.toLocal()}');
    print('$_tag now (device)  : ${DateTime.now()}');

    await _requireNotificationsEnabled();

    final canExact = await _android?.canScheduleExactNotifications();
    print('$_tag canExactAlarm : $canExact');
    if (canExact ?? true) return;

    // setAlarmClock throws ExactAlarmPermissionException without this. The
    // request opens a system Activity, which backgrounds the app; scheduling
    // anyway would throw against a still-denied permission and surface the
    // error on a screen nobody is looking at, so this stops here instead.
    print('$_tag exact alarms DENIED - opening system settings');
    await _android?.requestExactAlarmsPermission();
    throw StateError(
      'Izin "Alarms & reminders" belum aktif. Setelan sistem sudah dibuka: '
      'aktifkan izinnya, kembali ke app, lalu tekan tombol ini lagi.',
    );
  }

  static Future<void> cancelScheduled() {
    return LocalNotificationClient.plugin.cancel(_scheduleId);
  }

  /// Asks the OS for `POST_NOTIFICATIONS` directly rather than through
  /// [NotificationPermission], whose `notifPermissionAsked` latch would refuse
  /// to show the sheet a second time.
  static Future<bool> requestPermission() async {
    final android = _android;
    if (android == null) return NotificationPermission.request();
    final granted = await android.requestNotificationsPermission();
    print('$_tag requestNotificationsPermission -> $granted');
    return granted ?? false;
  }

  /// One-line summary of everything that decides whether a notification can
  /// reach the tray, so a failed QA run can be triaged from the toast alone.
  static Future<String> describeState() async {
    final android = _android;
    final enabled = await android?.areNotificationsEnabled();
    final canExact = await android?.canScheduleExactNotifications();
    final pending =
        await LocalNotificationClient.plugin.pendingNotificationRequests();
    final summary = 'notifs=$enabled exactAlarm=$canExact '
        'pending=${pending.map((r) => r.id).toList()}';
    print('$_tag $summary');
    return summary;
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      LocalNotificationClient.plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static void _ensureTimezone() {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_deviceLocation());
    _timezoneReady = true;
  }

  /// [tz_data.initializeTimeZones] leaves `tz.local` at UTC, which a relative
  /// schedule survives: `TZDateTime.now` captures the correct instant in any
  /// zone, and the plugin ships the zone name next to the wall clock, so the
  /// epoch millis AlarmManager receives are right either way. The cron jobs
  /// this layer stands in for fire at an absolute local hour though, where a
  /// UTC `local` would land seven hours out. Matching the device's current
  /// offset fixes that without a native timezone-lookup dependency.
  static tz.Location _deviceLocation() {
    final offset = DateTime.now().timeZoneOffset;
    bool matches(tz.Location location) =>
        tz.TZDateTime.now(location).timeZoneOffset == offset;

    // Preferred so the logs read in the zone the reminders are authored for,
    // rather than whichever same-offset zone happens to be first in the db.
    final jakarta = tz.timeZoneDatabase.locations['Asia/Jakarta'];
    if (jakarta != null && matches(jakarta)) return jakarta;

    return tz.timeZoneDatabase.locations.values.firstWhere(
      matches,
      orElse: () => tz.UTC,
    );
  }
}
