part of '_notification.dart';

/// Owns the unread-reminder count.
///
/// [PreferencesKeys.badgeCount] is the source of truth. The launcher badge is a
/// best-effort mirror only: Android has no universal badge API and support
/// varies by launcher, so the count must never be read back from the OS.
class BadgeService {
  static int get count => Pref.getInt(PreferencesKeys.badgeCount) ?? 0;

  static Future<void> increment() => _write(count + 1);

  static Future<void> reset() => _write(0);

  /// Re-applies the persisted count to the launcher on cold start.
  ///
  /// [incrementFromIsolate] can only reach SharedPreferences, so the launcher
  /// may be stale by the time the app is opened.
  static Future<void> restore() => _write(count);

  /// Increments from the FCM background isolate, where [Pref] is uninitialised
  /// and the launcher plugin channel is unavailable.
  static Future<void> incrementFromIsolate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(PreferencesKeys.badgeCount) ?? 0;
      await prefs.setInt(PreferencesKeys.badgeCount, current + 1);
    } catch (e) {
      Logger().w('BadgeService: isolate increment failed - $e');
    }
  }

  static Future<void> _write(int value) async {
    final safe = value < 0 ? 0 : value;
    await Pref.saveInt(PreferencesKeys.badgeCount, safe);
    await _mirrorToLauncher(safe);
  }

  static Future<void> _mirrorToLauncher(int value) async {
    if (kIsWeb) return;
    try {
      if (!await AppBadgePlus.isSupported()) return;
      await AppBadgePlus.updateBadge(value);
    } catch (e) {
      // Unsupported launchers throw instead of reporting false.
      Logger().w('BadgeService: launcher badge update failed - $e');
    }
  }
}
