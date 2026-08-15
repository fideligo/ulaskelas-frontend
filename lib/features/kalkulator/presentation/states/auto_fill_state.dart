part of '_states.dart';

/// Courses SLCM reports for one semester, driven by the autofill session API.
///
/// The backend owns a single remote browser, so the flow is: open a session,
/// send the student to `popupUrl` to log into SLCM by hand, then poll until the
/// scraper settles. [retrieveData] does not return until the session reaches a
/// settled state, which keeps `OnBuilder` on the waiting view for the whole
/// login and routes a failure to the error view.
///
/// Selection is read-only by design: the confirm endpoint imports everything
/// in `preview.matched` and ignores any body, so [toggle] is deliberately not
/// wired to the UI. See `auto_fill_page.dart`.
class AutoFillState implements FutureState<AutoFillState, String> {
  AutoFillState() {
    _repo = SlcmAutofillRepositoryImpl(SlcmAutofillRemoteDataSourceImpl());
  }

  /// How often to ask the backend whether the scrape has finished. The server
  /// expires an abandoned session on its own, and reports it as `expired` on
  /// the next poll, so this loop always terminates without a local deadline.
  static const _pollInterval = Duration(seconds: 3);

  late final SlcmAutofillRepository _repo;

  List<SiakCourseModel>? _courses;

  /// Held by identity rather than course code so a duplicated code in the
  /// SLCM response cannot make two rows toggle together.
  final Set<SiakCourseModel> _selected = {};

  String? _givenSemester;
  String? _sessionId;
  SlcmPreviewModel? _preview;
  SlcmSessionStatus _status = SlcmSessionStatus.unknown;

  Timer? _pollTimer;
  Completer<void>? _settled;

  /// Guards against a slow poll overlapping the next tick.
  bool _pollInFlight = false;

  /// Whether the login WebView was pushed and has not been closed from here.
  bool _loginPageOpen = false;

  List<SiakCourseModel> get courses => _courses ?? [];

  String? get givenSemester => _givenSemester;

  /// The live session, needed by the confirm call. Null before the session is
  /// opened and after it is cancelled.
  String? get sessionId => _sessionId;

  SlcmSessionStatus get status => _status;

  /// Whether the login WebView is still showing on the student's behalf.
  ///
  /// False once [_closeLoginPage] has dismissed it on a settled session, which
  /// is what stops the WebView's own dispose hook from cancelling a session
  /// that just succeeded.
  bool get isLoginPageOpen => _loginPageOpen;

  /// The full scrape result. `matched` is what [courses] renders; `duplicates`
  /// and `unmatched` are the rows the import will not touch.
  SlcmPreviewModel? get preview => _preview;

  /// How many courses SLCM returned that can actually be imported.
  int get totalFound => courses.length;

  int get selectedCount => _selected.length;

  /// Still in SLCM's order, not selection order.
  List<SiakCourseModel> get selectedCourses =>
      courses.where(_selected.contains).toList();

  bool isSelected(SiakCourseModel course) => _selected.contains(course);

  @override
  String? cacheKey = 'auto-fill-state';

  @override
  bool getCondition() => _courses?.isNotEmpty ?? false;

  @override
  Future<void> retrieveData(String givenSemester) async {
    _reset();
    _givenSemester = givenSemester;

    final created = await _repo.createSession(givenSemester);
    final session = created.fold<SlcmSessionModel>(
      (failure) => throw failure,
      (result) => result.data,
    );

    final sessionId = session.sessionId;
    if (sessionId == null) {
      throw GeneralFailure(message: 'Sesi SLCM tidak valid.');
    }
    _sessionId = sessionId;
    _status = session.status;

    // Deliberately not awaited: the push completes only when the page is
    // popped, and the poll below has to run while the student is still logging
    // in. SlcmWebViewPage loads the single-use URL exactly once.
    final popupUrl = session.popupUrl;
    if (popupUrl != null && popupUrl.isNotEmpty) {
      _loginPageOpen = true;
      unawaited(nav.goToSlcmWebViewPage(popupUrl));
    }

    autoFillRM.notify();
    await _pollUntilSettled(sessionId);
  }

  /// Cancels an in-flight session. Safe to call more than once.
  ///
  /// Releases the shared browser rather than leaving it locked until the
  /// server-side timeout — the backend refuses a second session while one is
  /// live, so an abandoned session blocks the student's next attempt.
  Future<void> cancel() async {
    _stopPolling();

    // Completed normally, not with an error: the listener is usually gone by
    // the time this runs, and an error on a dead future has nowhere to land.
    final settled = _settled;
    if (settled != null && !settled.isCompleted) {
      settled.complete();
    }
    _settled = null;

    final sessionId = _sessionId;
    _sessionId = null;
    if (sessionId == null || _status.isTerminal) {
      return;
    }
    await _repo.deleteSession(sessionId);
  }

  /// Cancels the session because the student backed out of the login WebView.
  ///
  /// This is the case that strands a session: the auto-fill page underneath
  /// survives the pop, so nothing else runs, and the backend keeps the shared
  /// browser locked until `SLCM_AUTOFILL_TIMEOUT_SECONDS` elapses — every
  /// retry in that window is refused with 409 `SESSION_ALREADY_ACTIVE`.
  ///
  /// The DELETE is awaited so the slot is free before the student can reach
  /// the button again.
  ///
  /// Unlike [cancel], which runs while the auto-fill page is being disposed,
  /// this leaves that page on screen — so it settles the poll with an error
  /// rather than completing quietly into an empty course list.
  Future<void> cancelFromLoginPage() async {
    // Cleared first: the WebView's dispose hook reads this to decide whether
    // it still needs to cancel, and must see the work already claimed.
    _loginPageOpen = false;
    _stopPolling();

    final settled = _settled;
    _settled = null;

    final sessionId = _sessionId;
    _sessionId = null;

    if (sessionId != null && !_status.isTerminal) {
      await _repo.deleteSession(sessionId);
    }
    _status = SlcmSessionStatus.cancelled;

    if (settled != null && !settled.isCompleted) {
      settled.completeError(
        GeneralFailure(message: 'Login SLCM dibatalkan.'),
      );
    }
    autoFillRM.notify();
  }

  /// Imports the scraped preview server-side.
  ///
  /// Throws the [Failure] so the caller can surface it. On success the session
  /// moves to `imported`, which is terminal — that is what stops [cancel] from
  /// then trying to DELETE a session that has already been consumed.
  Future<void> confirm(String sessionId) async {
    final resp = await _repo.confirmSession(sessionId);
    resp.fold(
      (failure) => throw failure,
      (result) => _status = result.data.status,
    );
  }

  void toggle(SiakCourseModel course) {
    if (!_selected.remove(course)) {
      _selected.add(course);
    }
    autoFillRM.notify();
  }

  Future<void> _pollUntilSettled(String sessionId) {
    final settled = Completer<void>();
    _settled = settled;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll(sessionId));
    return settled.future;
  }

  Future<void> _poll(String sessionId) async {
    if (_pollInFlight) {
      return;
    }
    _pollInFlight = true;
    try {
      final polled = await _repo.getSession(sessionId);
      polled.fold(
        _failWith,
        (result) => _apply(result.data),
      );
    } finally {
      _pollInFlight = false;
    }
  }

  void _apply(SlcmSessionModel session) {
    _status = session.status;

    if (session.status == SlcmSessionStatus.ready ||
        session.status == SlcmSessionStatus.imported) {
      _preview = session.preview;
      final courses = _mapMatched(session.preview);
      _courses = courses;
      // Everything SLCM matched is imported; the student cannot deselect.
      _selected
        ..clear()
        ..addAll(courses);
      _succeed();
      return;
    }

    if (session.status.isTerminal) {
      _failWith(GeneralFailure(message: _messageFor(session)));
      return;
    }

    // Still waiting on the login or the scrape. Notify so a later UI can show
    // which of the two it is.
    autoFillRM.notify();
  }

  List<SiakCourseModel> _mapMatched(SlcmPreviewModel? preview) {
    final matched = preview?.matched ?? const <SlcmPreviewCourseModel>[];
    return matched
        .map(
          (course) => SiakCourseModel(
            id: course.id,
            name: course.name,
            code: course.code,
            sks: course.sks,
            // SLCM's preview carries no wajib/pilihan flag and no faculty, so
            // both are left null; the card falls back to the course code.
          ),
        )
        .toList();
  }

  String _messageFor(SlcmSessionModel session) {
    final message = session.error?.message;
    if (message != null && message.isNotEmpty) {
      return message;
    }
    switch (session.status) {
      case SlcmSessionStatus.expired:
        return 'Sesi SLCM kedaluwarsa. Coba lagi.';
      case SlcmSessionStatus.cancelled:
        return 'Sesi SLCM dibatalkan.';
      case SlcmSessionStatus.failed:
      case SlcmSessionStatus.waitingLogin:
      case SlcmSessionStatus.scraping:
      case SlcmSessionStatus.ready:
      case SlcmSessionStatus.imported:
      case SlcmSessionStatus.unknown:
        return 'Gagal mengambil data dari SLCM.';
    }
  }

  void _succeed() {
    _stopPolling();
    _closeLoginPage();
    final settled = _settled;
    if (settled != null && !settled.isCompleted) {
      settled.complete();
    }
    autoFillRM.notify();
  }

  void _failWith(Failure failure) {
    _stopPolling();
    _closeLoginPage();
    final settled = _settled;
    if (settled != null && !settled.isCompleted) {
      settled.completeError(failure);
    }
  }

  /// Dismisses the login WebView once the session settles, so the student
  /// lands on the review list (or the error) rather than a spent noVNC screen.
  ///
  /// A no-op when the WebView was never opened or the student already backed
  /// out of it — popping to a route we are already on does nothing.
  void _closeLoginPage() {
    if (!_loginPageOpen) {
      return;
    }
    _loginPageOpen = false;
    nav.popUntil(RouteName.autoFillPage);
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
  }

  void _reset() {
    _stopPolling();
    _loginPageOpen = false;
    _settled = null;
    _courses = null;
    _selected.clear();
    _sessionId = null;
    _preview = null;
    _status = SlcmSessionStatus.unknown;
  }
}
