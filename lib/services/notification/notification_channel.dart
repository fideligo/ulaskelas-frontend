part of '_notification.dart';

/// Android channel + platform presentation definitions.
class NotificationChannels {
  /// Must match the
  /// `com.google.firebase.messaging.default_notification_channel_id` meta-data
  /// in AndroidManifest.xml. If the two differ, notifications rendered by FCM
  /// in the background or terminated state fall back to a system channel
  /// without heads-up display, while foreground notifications keep working.
  static const String highImportanceId = 'high_importance_channel';

  static const String _name = 'Pengingat TemanKuliah';
  static const String _description =
      'Pengingat pengisian kalkulator nilai dan ulasan mata kuliah.';

  static const AndroidNotificationChannel highImportance =
      AndroidNotificationChannel(
    highImportanceId,
    _name,
    description: _description,
    importance: Importance.high,
  );

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    highImportanceId,
    _name,
    channelDescription: _description,
    importance: Importance.high,
    priority: Priority.high,
    // TODO(team): supply a monochrome status bar drawable. Android renders a
    // non-alpha icon as a white square.
    icon: '@mipmap/ic_launcher',
  );

  // Defaults suffice: iOS foreground presentation is disabled in [FcmClient],
  // so notifications reach the user through this path only.
  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails();

  static const NotificationDetails details = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
  );
}
