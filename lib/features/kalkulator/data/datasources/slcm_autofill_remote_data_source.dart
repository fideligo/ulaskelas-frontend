part of '_datasources.dart';

/// The SLCM autofill session API.
///
/// The backend signs in to SLCM over HTTP and reads the IRS page itself, so the
/// whole run is server-side once [createSession] answers. It still allows a
/// single live session per user: create returns 409 `SESSION_ALREADY_ACTIVE`
/// rather than queueing. Cancel a session the student abandons instead of
/// leaving it to time out.
abstract class SlcmAutofillRemoteDataSource {
  Future<Parsed<SlcmSessionModel>> createSession(SlcmCredentials credentials);

  Future<Parsed<SlcmSessionModel>> getSession(String sessionId);

  Future<Parsed<void>> deleteSession(String sessionId);

  Future<Parsed<SlcmSessionModel>> confirmSession(String sessionId);
}

class SlcmAutofillRemoteDataSourceImpl implements SlcmAutofillRemoteDataSource {
  /// Receive window for the confirm call. Comfortably over the 5s default, and
  /// still well under the server's own session timeout.
  static const _confirmTimeout = Duration(seconds: 20);

  /// Opens a session with the student's SSO credentials, at status
  /// `authenticating`. Everything after this runs server-side.
  ///
  /// This is the only call that carries the password, and
  /// [SlcmCredentials.toRequestBody] is the only thing that can produce it —
  /// see that class for why it deliberately has no `toJson`.
  ///
  /// `given_semester` is omitted when the student left the field blank, which
  /// tells the backend to derive the semester from their NPM entry year and
  /// the running academic period. It echoes its choice back on every response.
  @override
  Future<Parsed<SlcmSessionModel>> createSession(
    SlcmCredentials credentials,
  ) async {
    final url = EndpointsRevamp.slcmAutofillSessions;
    final resp = await postIt(
      url,
      model: credentials.toRequestBody(),
    );
    return resp.parse(SlcmSessionModel.fromJson(resp.dataBodyAsMap));
  }

  /// Reads the session. This is the poll target: `preview` stays null until
  /// the status reaches `ready`.
  @override
  Future<Parsed<SlcmSessionModel>> getSession(String sessionId) async {
    final url = EndpointsRevamp.slcmAutofillSession(sessionId);
    final resp = await getIt(url);
    return resp.parse(SlcmSessionModel.fromJson(resp.dataBodyAsMap));
  }

  /// Cancels an unfinished session. Answers 204 with no body, and 409
  /// `SESSION_NOT_ACTIVE` if the session already settled.
  @override
  Future<Parsed<void>> deleteSession(String sessionId) async {
    final url = EndpointsRevamp.slcmAutofillSession(sessionId);
    final resp = await deleteIt(url);
    return resp.parse(null);
  }

  /// Imports the preview and returns the session with [SlcmSessionModel.result]
  /// filled in.
  ///
  /// Takes no body: the backend imports every course in `preview.matched` and
  /// ignores anything sent. Idempotent — confirming an already-imported
  /// session returns 200 rather than importing twice.
  ///
  /// The review step lets the student remove courses and
  /// `AutoFillState.excludedCourseCodes` names them, but nothing is posted
  /// here yet — `slcm_autofill_confirm` reads no request body, so sending one
  /// would only look like the exclusion worked. Add
  /// `model: {'excluded_course_codes': ...}` once the endpoint honours it.
  ///
  /// Given a longer receive window than the 5s default because this is the one
  /// call that does real work before answering: the import walks every matched
  /// course inside a single transaction, writing a `Calculator`, a
  /// `CourseSemester`, and recomputing the semester GPA for each.
  @override
  Future<Parsed<SlcmSessionModel>> confirmSession(String sessionId) async {
    final url = EndpointsRevamp.slcmAutofillConfirm(sessionId);
    final resp = await postIt(
      url,
      receiveTimeout: _confirmTimeout,
    );
    return resp.parse(SlcmSessionModel.fromJson(resp.dataBodyAsMap));
  }
}
