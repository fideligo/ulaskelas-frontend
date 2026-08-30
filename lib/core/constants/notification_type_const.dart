// Created by Muhamad Fauzi Ridwan on 07/08/21.

part of '_constants.dart';

/// Values of the `type` key inside a notification `data` payload.
///
/// These name *why* a notification was sent, not where tapping it leads —
/// that is [NotificationTarget]. Mirrors `Notification.Type` in the backend's
/// `main/models.py`; any value not listed here is treated as unroutable.
class NotificationType {
  static const String calculatorReminder = 'calculator_reminder';
  static const String courseReviewReminder = 'course_review_reminder';

  static const List<String> values = [
    calculatorReminder,
    courseReviewReminder,
  ];

  static bool isSupported(String? type) => values.contains(type);

  /// The screen a given [type] leads to, or null when the type is unknown.
  ///
  /// Used as the fallback when a payload carries no explicit `target`, which
  /// is the case for anything built locally rather than sent by the backend.
  static String? targetFor(String? type) {
    switch (type) {
      case calculatorReminder:
        return NotificationTarget.gradeCalculator;
      case courseReviewReminder:
        return NotificationTarget.courseReview;
      default:
        return null;
    }
  }
}

/// Values of the `target` key inside a notification `data` payload.
///
/// This is what the router switches on: the backend sends it precisely to say
/// which screen a tap should open, independently of the reminder that caused
/// it. Mirrors `Notification.Target` in the backend's `main/models.py`.
class NotificationTarget {
  static const String gradeCalculator = 'grade_calculator';
  static const String courseReview = 'course_review';

  static const List<String> values = [
    gradeCalculator,
    courseReview,
  ];

  static bool isSupported(String? target) => values.contains(target);
}
