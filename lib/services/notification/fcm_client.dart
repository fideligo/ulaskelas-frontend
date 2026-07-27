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

  /// Fetches and persists the registration token.
  ///
  /// Call after login so the token is tied to a signed-in user. Returns null
  /// when APNs has not issued a token, such as on an iOS simulator or when
  /// permission was denied.
  static Future<String?> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return null;
      await Pref.saveString(PreferencesKeys.fcmToken, token);
      if (kDebugMode) {
        // Consumed by QA when sending a test push from the Firebase Console.
        print('FCM token: $token');
      }
      return token;
    } catch (e) {
      Logger().w('FcmClient: getToken failed - $e');
      return null;
    }
  }

  /// Detaches the device from the account so a shared phone stops receiving
  /// the previous user's reminders.
  static Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      await Pref.removeKey(PreferencesKeys.fcmToken);
    } catch (e) {
      Logger().w('FcmClient: deleteToken failed - $e');
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
  }
}
