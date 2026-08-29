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
  /// Still needed now that [incrementFromIsolate] mirrors as it goes: a reboot,
  /// a launcher swap, or a launcher that dropped its own state leaves the badge
  /// showing nothing while the stored count says otherwise.
  static Future<void> restore() => _write(count);

  /// Increments from the FCM background isolate, where [Pref] is uninitialised,
  /// so [SharedPreferences] is reached directly instead.
  ///
  /// The launcher is mirrored from here too. This was previously assumed
  /// impossible — "the launcher plugin channel is unavailable" — but the
  /// background engine registers plugins just like the main one: the
  /// `SharedPreferences` call above is itself a method channel, and it works.
  /// Without this the count only reached the launcher on the next [restore],
  /// meaning the badge appeared only *after* the user opened the app, which is
  /// the moment it stops being useful. A launcher that genuinely cannot be
  /// reached still degrades quietly, because [_mirrorToLauncher] swallows it.
  static Future<void> incrementFromIsolate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = (prefs.getInt(PreferencesKeys.badgeCount) ?? 0) + 1;
      await prefs.setInt(PreferencesKeys.badgeCount, next);
      await _mirrorToLauncher(next);
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
