part of '_notification.dart';

/// Wrapper around flutter_local_notifications.
///
/// Renders every notification shown while the app is alive, including FCM
/// foreground messages: Android does not display those automatically, and iOS
/// presentation is disabled in [FcmClient], so both platforms use this path.
class LocalNotificationClient {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // Consent is owned by [NotificationPermission] and must not be requested
      // during the splash screen.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    // Only the foreground callback is registered. Taps on a terminated app are
    // read back via [initialPayload], and background taps arrive here on the
    // main isolate.
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(NotificationChannels.highImportance);
  }

  static Future<void> show(NotificationPayload payload) async {
    await _plugin.show(
      _idFor(payload),
      payload.title ?? _fallbackTitle(payload),
      payload.body ?? _fallbackBody(payload),
      NotificationChannels.details,
      payload: payload.toJsonString(),
    );
  }

  /// Payload of the notification that cold-started the app, if any.
  static Future<NotificationPayload?> initialPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || !details.didNotificationLaunchApp) return null;
      final response = details.notificationResponse;
      return NotificationPayload.tryParse(response?.payload);
    } catch (e) {
      Logger().w('LocalNotificationClient: launch details failed - $e');
      return null;
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static void _onResponse(NotificationResponse response) {
    final payload = NotificationPayload.tryParse(response.payload);
    if (payload == null) return;
    NotificationService.handleTap(payload);
  }

  /// Stable per (type, course) so a repeated reminder replaces the previous one
  /// instead of stacking. Masked to 31 bits because Android ids are `int32`.
  static int _idFor(NotificationPayload payload) {
    return '${payload.type}:${payload.matkulId ?? ''}'.hashCode & 0x7fffffff;
  }

  // Used only for data-only messages. Production wording is supplied in the
  // FCM `notification` block.
  static String _fallbackTitle(NotificationPayload payload) {
    return payload.isCourseReview
        ? 'Bagikan pengalaman matkul kamu'
        : 'Yuk, lengkapi Kalkulator Nilai!';
  }

  static String _fallbackBody(NotificationPayload payload) {
    return payload.isCourseReview
        ? 'Tulis ulasan singkat buat bantu teman-teman pilih mata kuliah.'
        : 'Sudah isi komponen nilai minggu ini? Cek progres IP kamu sekarang.';
  }
}
