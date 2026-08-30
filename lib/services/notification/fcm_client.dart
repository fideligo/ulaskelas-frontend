part of '_notification.dart';

/// Handles data messages that arrive while the app is backgrounded or dead.
///
/// Runs in a separate isolate with a cold Dart binding: [Pref] is
/// uninitialised, the navigator does not exist, and no injected state is
/// reachable. Limited to updating the persisted badge counter; routing occurs
/// once the app resumes.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await BadgeService.incrementFromIsolate();
}

/// Wrapper around firebase_messaging covering all three app states.
class FcmClient {
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Suppresses the iOS foreground banner (all options default to false) so
    // that [LocalNotificationClient] is the only renderer on both platforms.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Push that cold-started the app. Non-null exactly once per launch.
  static Future<NotificationPayload?> initialPayload() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) return null;
      return NotificationPayload.fromRemoteMessage(message);
    } catch (e) {
      Logger().w('FcmClient: getInitialMessage failed - $e');
      return null;
    }
  }

  /// The `platform` the backend expects, or null where it accepts neither.
  ///
  /// `device_token` rejects anything but `android`/`ios` with a 400, so web
  /// and desktop skip registration rather than posting a value that fails.
  static String? get _platform {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return DevicePlatform.android;
      case TargetPlatform.iOS:
        return DevicePlatform.ios;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  /// Fetches the registration token, persists it, and registers it with the
  /// backend so the reminder jobs have somewhere to send.
  ///
  /// Call after login: the backend ties the row to the signed-in user, so a
  /// token registered before auth would land on the wrong account. Safe to
  /// call on every launch — `device_token` upserts on the token itself.
  ///
  /// Returns null when APNs has not issued a token, such as on an iOS
  /// simulator or when permission was denied. A backend failure is logged but
  /// does not null the result: the token is still valid locally, and the next
  /// launch retries.
  static Future<String?> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return null;
      await Pref.saveString(PreferencesKeys.fcmToken, token);
      if (kDebugMode) {
        // Consumed by QA when sending a test push from the Firebase Console.
        print('FCM token: $token');
      }
      await _syncToBackend(token);
      return token;
    } catch (e) {
      Logger().w('FcmClient: getToken failed - $e');
      return null;
    }
  }

  /// Detaches the device from the account so a shared phone stops receiving
  /// the previous user's reminders.
  ///
  /// The backend is told first, because it keys the row on the token string
  /// and `FirebaseMessaging.deleteToken` invalidates it.
  static Future<void> deleteToken() async {
    final token = Pref.getString(PreferencesKeys.fcmToken);
    if (token != null && token.isNotEmpty) {
      await DeviceTokenApi.unregister(token);
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
      await Pref.removeKey(PreferencesKeys.fcmToken);
    } catch (e) {
      Logger().w('FcmClient: deleteToken failed - $e');
    }
  }

  /// Posts the token to `/api/device-tokens`. Never throws: a device that
  /// cannot be registered still gets a working app, just no pushes yet.
  static Future<void> _syncToBackend(String token) async {
    final platform = _platform;
    if (platform == null) return;
    final ok = await DeviceTokenApi.register(
      token: token,
      platform: platform,
    );
    if (!ok) {
      Logger().w('FcmClient: backend rejected the device token');
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = NotificationPayload.fromRemoteMessage(message);
    await BadgeService.increment();
    await LocalNotificationClient.show(payload);
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    NotificationService.handleTap(
      NotificationPayload.fromRemoteMessage(message),
    );
  }

  static Future<void> _onTokenRefresh(String token) async {
    await Pref.saveString(PreferencesKeys.fcmToken, token);
    Logger().i('FcmClient: registration token refreshed');
    // FCM rotates tokens without warning; the old row keeps pointing at a dead
    // token until the backend prunes it on a failed send.
    await _syncToBackend(token);
  }
}
