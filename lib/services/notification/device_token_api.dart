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
  }

  /// Detaches [token] so the device stops receiving this account's reminders.
  ///
  /// Answers 204 with no body. Sent before the local token is deleted, since
  /// the backend keys the row on the token string itself.
  static Future<bool> unregister(String token) async {
    final result = await apiCall(
      deleteIt(
        EndpointsRevamp.deviceTokens,
        model: <String, dynamic>{'token': token},
      ),
    );
    return result.fold((_) => false, (_) => true);
  }
}
