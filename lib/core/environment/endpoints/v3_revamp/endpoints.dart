part of '../../_environment.dart';

class EndpointsRevamp {
  static String baseUrl = Config.baseConfig.endpoints.baseUrl;
  // Calculator Revamp
  static final semesters = '$baseUrl/api/calculator-gpa';
  static final courses = '$baseUrl/api/course-semester';
  static final components = '$baseUrl/api/course-component';
  static final subcomponents = '$baseUrl/api/course-subcomponent';
  static final autofill = '$baseUrl/api/calculator-gpa?is_auto_fill=true';

  // SLCM autofill — session-based remote-browser flow.
  static final slcmAutofillSessions = '$baseUrl/api/slcm-autofill/sessions';
  static String slcmAutofillSession(String sessionId) =>
      '$baseUrl/api/slcm-autofill/sessions/$sessionId';
  static String slcmAutofillConfirm(String sessionId) =>
      '${slcmAutofillSession(sessionId)}/confirm';

  // Push notifications. POST registers the FCM token for the signed-in user,
  // DELETE detaches it on logout.
  static final deviceTokens = '$baseUrl/api/device-tokens';

  /// Clears the backend's unread tally, which it stamps into every push as
  /// `notification_count` — the number Android paints as the badge.
  static final notificationsReadAll = '$baseUrl/api/notifications/read-all';

  static final tanyaTeman = '$baseUrl/api/tanya-teman';
  static final jawabTeman = '$baseUrl/api/jawab-teman';
  static final likePost = '$baseUrl/api/tanya-teman?is_like=true';
  static final likeReply = '$baseUrl/api/jawab-teman?is_like=true';
}
