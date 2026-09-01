part of '_notification.dart';

/// Consent flow for `POST_NOTIFICATIONS` (Android 13+) and iOS alerts.
///
/// `FirebaseMessaging.requestPermission()` covers both platforms, so no
/// `permission_handler` dependency is required.
class NotificationPermission {
  /// Prompts at most once per install.
  ///
  /// Never blocks and never rethrows; a denial is an ordinary outcome. Must
  /// not be called during splash, where the OS sheet would overlay a loading
  /// screen.
  static Future<bool> requestIfNeeded() async {
    final asked = Pref.getBool(PreferencesKeys.notifPermissionAsked) ?? false;
    if (asked) return isGranted();

    // Recorded before awaiting the sheet so that backgrounding the app while it
    // is open does not cause a re-prompt on the next launch.
    await Pref.saveBool(PreferencesKeys.notifPermissionAsked, value: true);
    return request();
  }

  /// Shows the OS permission sheet unconditionally. Prefer [requestIfNeeded].
  static Future<bool> request() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      Logger().i(
        'NotificationPermission: ${settings.authorizationStatus}',
      );
      return _isAuthorized(settings.authorizationStatus);
    } catch (e) {
      // A missing APNs entitlement or an iOS simulator throws here.
      Logger().w('NotificationPermission: request failed - $e');
      return false;
    }
  }

  static Future<bool> isGranted() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return _isAuthorized(settings.authorizationStatus);
    } catch (_) {
      return false;
    }
  }

  static bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }
}
