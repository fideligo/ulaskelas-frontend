part of '_notification.dart';

/// Installed by the routing layer to turn a payload into navigation.
typedef NotificationTapHandler = void Function(NotificationPayload payload);

/// Entry point for the notification stack.
///
/// Holds no navigation logic. The routing layer installs itself via
/// [onPayloadTapped]; until then taps are parked rather than dropped, so a
/// cold-start tap survives the splash and auth window.
class NotificationService {
  static NotificationTapHandler? onPayloadTapped;

  static NotificationPayload? _pending;
  static bool _initialized = false;

  /// Wires up both transports. Called from `Config.init` after `Pref.init`,
  /// on which [BadgeService] depends.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await LocalNotificationClient.init();
      await FcmClient.init();
      await BadgeService.restore();
    } catch (e, s) {
      // Notification setup is not load-bearing for app start.
      Logger().e('NotificationService: init failed', error: e, stackTrace: s);
    }
  }

  /// The payload that cold-started the app, from either transport. Returns
  /// non-null at most once per launch, so it must be consumed in one place.
  static Future<NotificationPayload?> takeLaunchPayload() async {
    final fromPush = await FcmClient.initialPayload();
    if (fromPush != null) return fromPush;
    return LocalNotificationClient.initialPayload();
  }

  /// Single funnel for every tap, from any transport or app state.
  static void handleTap(NotificationPayload payload) {
    unawaited(BadgeService.reset());
    final handler = onPayloadTapped;
    if (handler == null) {
      _pending = payload;
      return;
    }
    handler(payload);
  }

  /// Parks a payload for later replay. Used by the router when a handler is
  /// installed but the app cannot navigate yet, such as mid-splash or before
  /// auth has resolved.
  static void park(NotificationPayload payload) => _pending = payload;

  /// Drains a tap that arrived before [onPayloadTapped] was installed.
  static NotificationPayload? takePending() {
    final payload = _pending;
    _pending = null;
    return payload;
  }

  /// Clears the tray and the badge counter.
  static Future<void> clearAll() async {
    await LocalNotificationClient.cancelAll();
    await BadgeService.reset();
  }

  @visibleForTesting
  static void resetForTest() {
    _initialized = false;
    _pending = null;
    onPayloadTapped = null;
  }
}
