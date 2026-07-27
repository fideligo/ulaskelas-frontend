part of '../_notification.dart';

/// Typed view over the `data` map of a push or local notification.
///
/// FCM delivers every `data` value as a string, so parsing is defensive
/// throughout: a malformed payload surfaces as an unsupported [type] instead of
/// throwing. These constructors run inside message handlers, one of them in a
/// background isolate, where an exception would silently kill the callback.
@immutable
class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.matkulId,
    this.courseCode,
    this.title,
    this.body,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: _asString(map[keyType]) ?? '',
      matkulId: _asString(map[keyMatkulId]),
      courseCode: _asString(map[keyCourseCode]),
      title: _asString(map[keyTitle]),
      body: _asString(map[keyBody]),
    );
  }

  /// Reminder to fill in grade components. Carries no extra arguments.
  factory NotificationPayload.calculator({String? title, String? body}) {
    return NotificationPayload(
      type: NotificationType.calculator,
      title: title,
      body: body,
    );
  }

  /// Reminder to review a course. [matkulId] is required to resolve the form;
  /// [courseCode] is the fallback route argument when hydration fails.
  factory NotificationPayload.courseReview({
    required String matkulId,
    String? courseCode,
    String? title,
    String? body,
  }) {
    return NotificationPayload(
      type: NotificationType.courseReview,
      matkulId: matkulId,
      courseCode: courseCode,
      title: title,
      body: body,
    );
  }

  static const String keyType = 'type';
  static const String keyMatkulId = 'matkul_id';
  static const String keyCourseCode = 'course_code';
  static const String keyTitle = 'title';
  static const String keyBody = 'body';

  final String type;
  final String? matkulId;
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

  bool get isSupported => NotificationType.isSupported(type);

  bool get isCalculator => type == NotificationType.calculator;

  bool get isCourseReview => type == NotificationType.courseReview;

  /// [matkulId] arrives as a string over the wire. Null when absent or when it
  /// cannot be parsed as an integer.
  int? get courseId => int.tryParse(matkulId ?? '');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyType: type,
      if (matkulId != null) keyMatkulId: matkulId,
      if (courseCode != null) keyCourseCode: courseCode,
      if (title != null) keyTitle: title,
      if (body != null) keyBody: body,
    };
  }

  String toJsonString() => jsonEncode(toMap());

  NotificationPayload copyWith({
    String? type,
    String? matkulId,
    String? courseCode,
    String? title,
    String? body,
  }) {
    return NotificationPayload(
      type: type ?? this.type,
      matkulId: matkulId ?? this.matkulId,
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
        other.matkulId == matkulId &&
        other.courseCode == courseCode &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode => Object.hash(type, matkulId, courseCode, title, body);
}
