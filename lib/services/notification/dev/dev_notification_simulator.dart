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
    await BadgeService.increment();
    await LocalNotificationClient.show(payload);
  }

  /// Layer 3: stands in for the Friday 16:00 and end-of-month cron jobs.
  ///
  /// To exercise the terminated state, schedule a notification, force-kill the
  /// app from the recents switcher, then tap it. This is the only reliable way
  /// to cover `getNotificationAppLaunchDetails` and the parked-payload replay.
  static Future<void> schedule(
    NotificationPayload payload, {
    Duration after = const Duration(seconds: 15),
  }) async {
    _ensureTimezone();
    await LocalNotificationClient.plugin.zonedSchedule(
      _scheduleId,
      payload.title ?? '[DEV] ${payload.type}',
      payload.body ?? 'Dijadwalkan ${after.inSeconds} detik yang lalu.',
      tz.TZDateTime.now(tz.local).add(after),
      NotificationChannels.details,
      payload: payload.toJsonString(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Inexact scheduling avoids declaring SCHEDULE_EXACT_ALARM, a permission
      // the production app has no use for. Drift is acceptable for QA.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelScheduled() {
    return LocalNotificationClient.plugin.cancel(_scheduleId);
  }

  /// Relative scheduling requires a correct instant, not a correct zone name,
  /// so the default UTC location is sufficient and no native timezone lookup
  /// dependency is needed.
  static void _ensureTimezone() {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    _timezoneReady = true;
  }
}
