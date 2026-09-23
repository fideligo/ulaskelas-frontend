/// SSO credentials for one SLCM autofill run.
///
/// The backend signs in to SLCM over HTTP on the student's behalf, so it needs
/// the password once, at session creation. Nothing else in the app ever does.
///
/// ## The password must not outlive the request
///
/// This object is built in the credential sheet, handed straight to
/// `createSession`, and dropped. It is deliberately hostile to every other use:
///
/// * [toRequestBody] is the only member that exposes [password]. There is no
///   `toJson`, so this cannot be persisted by a `jsonEncode` somewhere else.
/// * [toString] redacts, which is what keeps the password out of `print`,
///   `Logger`, and a Crashlytics stack frame that happens to capture this
///   object.
/// * No field is written to `SharedPreferences` — see the `Pref` facade, which
///   this file never touches.
///
/// `test/unit/slcm_credentials_test.dart` pins the redaction, and
/// `tool/audit_password_leaks.dart` greps for regressions.
class SlcmCredentials {
  SlcmCredentials({
    required String username,
    required this.password,
    String? givenSemester,
  })  : username = username.trim(),
        givenSemester = _normaliseSemester(givenSemester);

  /// SSO UI username, e.g. `muhammad.rafi419`. Trimmed on the way in: a
  /// trailing space from an autofilled keyboard is the usual cause of a
  /// spurious `INVALID_CREDENTIALS`.
  final String username;

  /// Held in memory for the lifetime of one request and never written down.
  final String password;

  /// Optional override for the semester being filled, e.g. `'5'`.
  ///
  /// Null means "let the backend decide" — it derives the current semester
  /// from the student's NPM entry year and the running academic period. Blank
  /// input is normalised to null so an untouched field behaves the same way.
  final String? givenSemester;

  /// Whether both required fields carry something. The sheet gates its submit
  /// button on this rather than re-implementing the rule.
  bool get isComplete => username.isNotEmpty && password.isNotEmpty;

  /// The `POST /api/slcm-autofill/sessions` body.
  ///
  /// `given_semester` is omitted rather than sent as null when the student did
  /// not supply one: the backend treats a missing key as "derive it" and
  /// answers `INVALID_SEMESTER` for a present-but-empty value.
  Map<String, dynamic> toRequestBody() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      if (givenSemester != null) 'given_semester': givenSemester,
    };
  }

  static String? _normaliseSemester(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// Redacted on purpose. Anything that stringifies this object — a logger, an
  /// assertion message, a crash report — gets the shape without the secret.
  @override
  String toString() {
    return 'SlcmCredentials(username: $username, '
        'password: <redacted>, givenSemester: $givenSemester)';
  }
}
