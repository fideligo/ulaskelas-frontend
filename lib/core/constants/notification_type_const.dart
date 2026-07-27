// Created by Muhamad Fauzi Ridwan on 07/08/21.

part of '_constants.dart';

/// Values of the `type` key inside a notification `data` payload.
///
/// Must stay in sync with the backend scheduler contract. Any value not listed
/// here is treated as unroutable.
class NotificationType {
  static const String calculator = 'CALCULATOR';
  static const String courseReview = 'COURSE_REVIEW';

  static const List<String> values = [
    calculator,
    courseReview,
  ];

  static bool isSupported(String? type) => values.contains(type);
}
