part of '_datasources.dart';

/// The SLCM autofill session API.
///
/// One shared remote browser sits behind these calls, so the backend allows a
/// single live session per user and a single one globally: create returns 409
/// `SESSION_ALREADY_ACTIVE` or `BROWSER_BUSY` rather than queueing. Cancel a
/// session the student abandons instead of leaving it to time out.
abstract class SlcmAutofillRemoteDataSource {
  Future<Parsed<SlcmSessionModel>> createSession(String givenSemester);

  Future<Parsed<SlcmSessionModel>> getSession(String sessionId);

  Future<Parsed<void>> deleteSession(String sessionId);

  Future<Parsed<SlcmSessionModel>> confirmSession(String sessionId);
}

class SlcmAutofillRemoteDataSourceImpl implements SlcmAutofillRemoteDataSource {
  /// Receive window for the confirm call. Comfortably over the 5s default, and
  /// still well under the server's own session timeout.
  static const _confirmTimeout = Duration(seconds: 20);

  /// Opens a session and returns it with `popupUrl` set, at status
  /// `waiting_login`. The scraper starts server-side straight away; nothing is
  /// scraped until the student finishes logging in through the popup.
  ///
  /// [givenSemester] is the semester label as a string — `'1'`, not `1`.
  @override
  Future<Parsed<SlcmSessionModel>> createSession(String givenSemester) async {
    final url = EndpointsRevamp.slcmAutofillSessions;
    final resp = await postIt(
      url,
      model: <String, dynamic>{'given_semester': givenSemester},
    );
    return resp.parse(SlcmSessionModel.fromJson(resp.dataBodyAsMap));
  }

  /// Reads the session. This is the poll target: `preview` stays null until
  /// the status reaches `ready`, and `popupUrl` is never included here.
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
