part of '../_notification.dart';

/// Typed view over the `data` map of a push or local notification.
///
/// Mirrors the map built by the backend's `push_notifications.send_push`:
/// `type`, `target`, and `course_id` when the reminder is about one course.
/// [target] is what the router acts on; [type] only says which reminder
/// produced it.
///
/// FCM delivers every `data` value as a string, so parsing is defensive
/// throughout: a malformed payload surfaces as an unsupported [type] instead of
/// throwing. These constructors run inside message handlers, one of them in a
/// background isolate, where an exception would silently kill the callback.
@immutable
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.target,
    this.courseId,
    this.courseCode,
    this.title,
    this.body,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: _asString(map[keyType]) ?? '',
      target: _asString(map[keyTarget]),
      courseId: _asString(map[keyCourseId]),
      courseCode: _asString(map[keyCourseCode]),
      title: _asString(map[keyTitle]),
      body: _asString(map[keyBody]),
    );
  }

  /// Reminder to fill in grade components. Carries no extra arguments.
  factory NotificationPayload.calculator({String? title, String? body}) {
    return NotificationPayload(
      type: NotificationType.calculatorReminder,
      target: NotificationTarget.gradeCalculator,
      title: title,
      body: body,
    );
  }

  /// Reminder to review a course. [courseId] is required to resolve the form;
  /// [courseCode] is the fallback route argument when hydration fails.
  factory NotificationPayload.courseReview({
    required String courseId,
    String? courseCode,
    String? title,
    String? body,
  }) {
    return NotificationPayload(
      type: NotificationType.courseReviewReminder,
      target: NotificationTarget.courseReview,
      courseId: courseId,
      courseCode: courseCode,
      title: title,
      body: body,
    );
  }

  static const String keyType = 'type';
  static const String keyTarget = 'target';
  static const String keyCourseId = 'course_id';

  /// Not sent by the backend today — `send_push` carries only `course_id`.
  /// Retained because the router still uses it to reach the detail page when
  /// hydration fails, and the dev simulator supplies it.
  static const String keyCourseCode = 'course_code';
  static const String keyTitle = 'title';
  static const String keyBody = 'body';

  final String type;

  /// Null when the sender omitted it; [routingTarget] derives one from [type].
  final String? target;

  /// The backend's `course_id`, as the string FCM delivers it.
  final String? courseId;
  final String? courseCode;
  final String? title;
  final String? body;

  /// Parses the JSON string carried by a local notification's `payload` field.
  /// Returns null on anything unparseable rather than throwing.
  static NotificationPayload? tryParse(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return NotificationPayload.fromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Builds a payload from an FCM message, falling back to the notification
  /// block for display text when the data block omits it.
  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final base = NotificationPayload.fromMap(message.data);
    final notification = message.notification;
    if (notification == null) return base;
    return base.copyWith(
      title: base.title ?? notification.title,
      body: base.body ?? notification.body,
    );
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// The screen this payload should open.
  ///
  /// Prefers the backend's explicit `target`, falling back to the one implied
  /// by [type] so a sender that omits the key still routes.
  String? get routingTarget {
    if (NotificationTarget.isSupported(target)) return target;
    return NotificationType.targetFor(type);
  }

  /// Whether this payload can be routed at all. A payload is usable when
  /// either key resolves, so an unrecognised [type] carrying a known [target]
  /// still reaches the right screen.
  bool get isSupported => routingTarget != null;

  bool get isCalculator =>
      routingTarget == NotificationTarget.gradeCalculator;

  bool get isCourseReview => routingTarget == NotificationTarget.courseReview;

  /// [courseId] arrives as a string over the wire. Null when absent or when it
  /// cannot be parsed as an integer.
  int? get courseIdValue => int.tryParse(courseId ?? '');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyType: type,
      if (target != null) keyTarget: target,
      if (courseId != null) keyCourseId: courseId,
      if (courseCode != null) keyCourseCode: courseCode,
      if (title != null) keyTitle: title,
      if (body != null) keyBody: body,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  NotificationPayload copyWith({
    String? type,
    String? target,
    String? courseId,
    String? courseCode,
    String? title,
    String? body,
  }) {
    return NotificationPayload(
      type: type ?? this.type,
      target: target ?? this.target,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  @override
  String toString() => 'NotificationPayload(${toJsonString()})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPayload &&
        other.type == type &&
        other.target == target &&
        other.courseId == courseId &&
        other.courseCode == courseCode &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode =>
      Object.hash(type, target, courseId, courseCode, title, body);
}
