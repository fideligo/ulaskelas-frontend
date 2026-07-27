// Standalone library rather than a `part of _notification.dart`: the service
// layer stays free of the app's state and page graph so it remains testable
// without a NavigatorState. This file is the single point where the two meet.

import 'dart:async';

import 'package:logger/logger.dart';
import 'package:ulaskelas/core/bases/states/_states.dart';
import 'package:ulaskelas/core/constants/_constants.dart';
import 'package:ulaskelas/services/_services.dart';
import 'package:ulaskelas/services/notification/_notification.dart';

/// Turns a [NotificationPayload] into navigation.
abstract class NotificationRouter {
  /// Installs this router as the tap handler and replays any payload that
  /// arrived during startup.
  ///
  /// Call once the user is authenticated and `MainPage` is on screen.
  static Future<void> attach() async {
    NotificationService.onPayloadTapped = (payload) => unawaited(
          handle(payload),
        );

    final parked = NotificationService.takePending();
    if (parked != null) {
      await handle(parked);
      return;
    }

    // Nothing parked, so this may be a cold start from the notification tray.
    final launch = await NotificationService.takeLaunchPayload();
    if (launch != null) await handle(launch);
  }

  /// Single funnel for every notification tap, in every app state.
  static Future<void> handle(NotificationPayload payload) async {
    if (!payload.isSupported) {
      Logger().w('NotificationRouter: unroutable type "${payload.type}"');
      return;
    }

    // Navigating before the navigator exists throws, and navigating before auth
    // resolves would place a logged-out user on an authenticated screen.
    if (!_isReady) {
      NotificationService.park(payload);
      return;
    }

    MixpanelService.track(
      'notification_opened',
      params: {'type': payload.type},
    );

    switch (payload.type) {
      case NotificationType.calculator:
        _goToCalculator();
      case NotificationType.courseReview:
        await _goToCourseReview(payload);
    }
  }

  static bool get _isReady =>
      nav.navigatorKey.currentState != null && authRM.state.isLogin;

  static void _goToCalculator() {
    _returnToMainPage();
    mainTabRM.state = MainTab.kalkulator;
  }

  static Future<void> _goToCourseReview(NotificationPayload payload) async {
    final courseId = payload.courseId;
    if (courseId == null) {
      Logger().w('NotificationRouter: course review without a usable id');
      _fallbackToMatkulTab();
      return;
    }

    _returnToMainPage();

    // The review form needs a fully hydrated CourseModel; the payload only
    // carries an id, so it has to be fetched before the form can be pushed.
    try {
      await courseDetailRM.setState((s) => s.retrieveData(courseId));
      if (courseDetailRM.hasData) {
        await nav.goToReviewMatkulFormPage(
          course: courseDetailRM.state.detailCourse,
        );
        return;
      }
    } catch (e) {
      // Offline, 404, or a deleted course. A 403 is already converted into a
      // forced SSO redirect by apiCall.
      Logger().w('NotificationRouter: course hydration failed - $e');
    }

    // Degrade to the detail page, which exposes its own "Tulis Ulasan" button.
    final courseCode = payload.courseCode;
    if (courseCode != null) {
      await nav.goToDetailMatkulPage(courseId, courseCode);
      return;
    }
    _fallbackToMatkulTab();
  }

  static void _fallbackToMatkulTab() {
    _returnToMainPage();
    mainTabRM.state = MainTab.matkul;
  }

  /// Collapses stacked routes so that the tab switch becomes visible.
  ///
  /// `FilterPage` is also pushed under [RouteName.mainPage], so this stops at
  /// the filter sheet when it is open. The tab still changes beneath it.
  // TODO(team): give FilterPage its own route name to remove the collision.
  static void _returnToMainPage() {
    if (!nav.canPop()) return;
    nav.popUntil(RouteName.mainPage);
  }
}
