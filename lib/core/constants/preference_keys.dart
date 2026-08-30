// Created by Muhamad Fauzi Ridwan on 29/11/21.

part of '_constants.dart';

class PreferencesKeys {
  static const onBoard = 'PrefKey onBoard';
  static const ulasKelasCred = 'PrefKey ulasKelasCred';

  /// Source of truth for the app icon badge; the OS badge mirrors this value.
  static const badgeCount = 'PrefKey badgeCount';

  /// Last FCM registration token sent to the backend.
  static const fcmToken = 'PrefKey fcmToken';

  /// Set once the permission sheet has been shown, so that a denial is not
  /// re-prompted on every cold start. Intentionally survives logout.
  static const notifPermissionAsked = 'PrefKey notifPermissionAsked';

  static const removableKeys = [
    ulasKelasCred,
    badgeCount,
    fcmToken,
  ];
}
