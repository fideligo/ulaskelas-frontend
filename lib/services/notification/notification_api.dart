// Standalone library rather than a `part of _notification.dart`, matching
// `notification_router.dart`: the HTTP client pulls in the app's state layer,
// which already imports this service. Keeping the call here leaves the
// transport files free of that edge.

import 'package:ulaskelas/core/client/_client.dart';
import 'package:ulaskelas/core/environment/_environment.dart';

/// The `platform` values `views_notification.device_token` accepts. Anything
/// else is rejected with 400, so an unsupported platform never registers.
class DevicePlatform {
  static const String android = 'android';
  static const String ios = 'ios';
}

/// Wraps `POST`/`DELETE /api/device-tokens`.
///
/// Every method resolves rather than throws: registration is a side errand of
/// signing in and of logging out, and neither should fail because the device
/// could not be recorded. `apiCall` still classifies the failure, so a 403
/// forces the SSO redirect exactly as it does elsewhere.
abstract class DeviceTokenApi {
  /// Registers [token] against the signed-in user.
  ///
  /// The backend upserts on the token itself, so calling this on every launch
  /// is safe and is what re-attaches a device after a reinstall or a token
  /// refresh. Returns whether the backend accepted it.
  static Future<bool> register({
    required String token,
    required String platform,
  }) async {
    try {
      final result = await apiCall(
        postIt(
          EndpointsRevamp.deviceTokens,
          model: <String, dynamic>{
            'token': token,
            'platform': platform,
          },
        ),
      );
      return result.fold((_) => false, (_) => true);
    } catch (_) {
      return false;
    }
  }

  /// Detaches [token] so the device stops receiving this account's reminders.
  ///
  /// Answers 204 with no body. Sent before the local token is deleted, since
  /// the backend keys the row on the token string itself.
  static Future<bool> unregister(String token) async {
    try {
      final result = await apiCall(
        deleteIt(
          EndpointsRevamp.deviceTokens,
          model: <String, dynamic>{'token': token},
        ),
      );
      return result.fold((_) => false, (_) => true);
    } catch (_) {
      // Logout must not be blocked by an unreachable backend.
      return false;
    }
  }
}


/// Wraps the notification inbox endpoints.
abstract class NotificationApi {
  /// Marks every unread notification read, zeroing the tally the backend keeps.
  ///
  /// That tally is the one Android actually shows: `send_push` stamps it into
  /// each message as `notification_count`, which the platform renders as the
  /// badge and which therefore overrides whatever the client last mirrored.
  /// Resetting the local count alone leaves the two disagreeing, and the next
  /// push repaints the server's stale number.
  ///
  /// Resolves rather than throws — this trails a UI action nobody is waiting
  /// on, and the next open retries it anyway.
  static Future<bool> markAllRead() async {
    try {
      final result = await apiCall(
        postIt(
          EndpointsRevamp.notificationsReadAll,
          model: const <String, dynamic>{},
        ),
      );
      return result.fold((_) => false, (_) => true);
    } catch (_) {
      // `apiCall` folds transport failures, but building the URL happens first
      // and can throw on its own: `baseUrl` reads `Config`, which is unset
      // until the app boots. Clearing a badge must not hinge on that.
      return false;
    }
  }
}
