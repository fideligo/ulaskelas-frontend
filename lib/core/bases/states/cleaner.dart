part of '_states.dart';

abstract class StateCleaner {
  void cleanState();

  Future<void> cleanWhenLogout();
}

class Cleaner implements StateCleaner {
  @override
  void cleanState() {}

  @override
  Future<void> cleanWhenLogout() async {
    for (final key in PreferencesKeys.removableKeys) {
      await Pref.removeKey(key);
    }
    // Detaches the device so a shared phone stops receiving the previous
    // account's reminders. FcmClient handles its own failures, so an
    // unavailable network cannot block logout.
    await FcmClient.deleteToken();
  }
}
