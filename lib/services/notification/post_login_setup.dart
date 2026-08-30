// Standalone library, like notification_router.dart: this needs both the
// notification service layer and NotificationRouter (the app's state and
// navigation), which `_notification.dart`'s barrel deliberately keeps free of
// navigation so that layer stays testable without a NavigatorState.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ulaskelas/services/notification/_notification.dart';
import 'package:ulaskelas/services/notification/routing/notification_router.dart';

/// Everything that must run once a user is authenticated and `MainPage` is on
/// screen: deep-link routing and FCM device registration.
///
/// Call this from every place that completes login. There are three today —
/// cold-start resume (`AppWrapper`), the interactive SSO webview
/// (`AuthenticationPage`), and the web popup flow (`AuthState`) — and each one
/// used to wire `NotificationRouter.attach()` and `FcmClient.registerToken()`
/// up on its own. That is how the interactive login path silently lost device
/// registration: the calls only ever lived in `AppWrapper`'s cold-start
/// branch, so a fresh sign-in through the SSO button never ran them, and every
/// push aimed at that device failed once its Firebase Instance ID rotated (an
/// uninstall or a fresh `FirebaseApp` after a `google-services.json` swap
/// makes the token FCM had on file `NOT_FOUND`).
///
/// Deferred a frame so the navigator has settled onto `MainPage` before a
/// deep link or `registerToken()`'s network call runs — each caller pushes
/// that page immediately before this, but `pushReplacement`'s future only
/// resolves once `MainPage` is itself popped, which is not yet.
void onLoginCompleted() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(NotificationRouter.attach());
    unawaited(FcmClient.registerToken());
  });
}
