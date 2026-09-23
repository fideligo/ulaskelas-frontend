part of '_states.dart';

/// Courses SLCM reports for one semester, driven by the autofill session API.
///
/// The backend signs in to SLCM over HTTP itself, so the flow is: open a
/// session with the student's SSO credentials, then poll until the importer
/// settles. [retrieveData] does not return until the session reaches a settled
/// state, which keeps `OnBuilder` on the waiting view for the whole run and
/// routes a failure to the error view.
///
/// [retrieveData] takes the credentials and nothing else. `givenSemester` is
/// optional inside them: left blank, the backend works out which semester the
/// student is in from their NPM and hands it back on the session, so
/// [givenSemester] is filled from the response — see
/// `slcm_autofill_remote_data_source.dart`.
///
/// The password reaches this class only inside [SlcmCredentials] and is never
/// assigned to a field: it lives in the `retrieveData` frame and goes out of
/// scope when the create call returns.
///
/// Everything `preview.matched` holds starts kept, and [remove] drops a row
/// the student does not want. That choice is local for now: the confirm
/// endpoint takes no body and imports the whole preview, so [excludedCourses]
/// is tracked and ready but nothing sends it yet. See `auto_fill_page.dart`.
class AutoFillState implements FutureState<AutoFillState, SlcmCredentials> {
  AutoFillState() {
    _repo = SlcmAutofillRepositoryImpl(SlcmAutofillRemoteDataSourceImpl());
  }

  /// How often to ask the backend whether the scrape has finished. The server
  /// expires an abandoned session on its own, and reports it as `expired` on
  /// the next poll, so this loop always terminates without a local deadline.
  static const _pollInterval = Duration(seconds: 3);

  late final SlcmAutofillRepository _repo;

  List<SiakCourseModel>? _courses;

  /// Held apart from [_courses] because the import skips these: they are shown
  /// so the student can see SLCM found them, and nothing more.
  List<SiakCourseModel>? _duplicates;

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

  /// The backend's `error.code` for the run that just failed, or null.
  ///
  /// Kept so the calling page can tell a mistyped password apart from an SLCM
  /// outage and reopen the credential sheet only for the former.
  String? _lastErrorCode;

  /// Every course SLCM matched, including the ones the student has removed.
  List<SiakCourseModel> get courses => _courses ?? [];

  /// Courses already in this semester's calculator. Never importable, so they
  /// are drawn greyed out and cannot be removed.
  List<SiakCourseModel> get duplicateCourses => _duplicates ?? [];

  /// The semester the backend picked for this session, e.g. `'9'`.
  ///
  /// Null until the create call answers; the review and confirmation screens
  /// label themselves off it once it lands.
  String? get givenSemester => _givenSemester;

  /// The live session, needed by the confirm call. Null before the session is
  /// opened and after it is cancelled.
  String? get sessionId => _sessionId;

  SlcmSessionStatus get status => _status;

  /// The backend's failure code for the last settled run, or null.
  String? get lastErrorCode => _lastErrorCode;

  /// Whether the last failure was the credentials rather than SLCM itself.
  bool get lastFailureWasCredentials =>
      SlcmErrorCode.isCredentialProblem(_lastErrorCode);

  /// The full result. `matched` is what [courses] renders; `duplicates` and
  /// `unmatched` are the rows the import will not touch.
  SlcmPreviewModel? get preview => _preview;

  /// Rows SLCM reported that no local course matched. Informational only.
  List<SlcmUnmatchedCourseModel> get unmatchedCourses =>
      _preview?.unmatched ?? const [];

  /// Whether the backend flagged the IRS data as possibly out of date.
  ///
  /// Advisory only: the review screen shows a banner and the import still runs.
  bool get hasStaleDataWarning => _preview?.warningStaleData ?? false;

  /// How many courses SLCM returned that can actually be imported.
  int get totalFound => courses.length;

  int get selectedCount => _selected.length;

  /// Still in SLCM's order, not selection order.
  List<SiakCourseModel> get selectedCourses =>
      courses.where(_selected.contains).toList();

  /// Courses the student removed from the preview.
  ///
  /// Populated and kept correct so the confirm call can start sending it the
  /// moment the backend grows an `excluded_course_codes` payload. Until then
  /// nothing reads it over the wire and the import still takes every matched
  /// course — see `slcm_autofill_remote_data_source.dart`.
  List<SiakCourseModel> get excludedCourses =>
      courses.where((course) => !_selected.contains(course)).toList();

  /// [excludedCourses] as the codes a future confirm payload would carry.
  List<String> get excludedCourseCodes => excludedCourses
      .map((course) => course.code)
      .whereType<String>()
      .toList();

  bool isSelected(SiakCourseModel course) => _selected.contains(course);

  @override
  String? cacheKey = 'auto-fill-state';

  @override
  bool getCondition() => _courses?.isNotEmpty ?? false;

  @override
  Future<void> retrieveData([SlcmCredentials? credentials]) async {
    _reset();

    if (credentials == null || !credentials.isComplete) {
      throw GeneralFailure(message: 'Username dan password SSO wajib diisi.');
    }

    // The only point the password is in play. It is not assigned to a field,
    // so nothing outside this frame can reach it once the call returns.
    final created = await _repo.createSession(credentials);
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
    // The semester the backend resolved off the student's NPM. Recorded here
    // so the waiting view can already name it, ahead of the first poll.
    _givenSemester = session.givenSemester;

    // A create that settles immediately - rejected credentials, for instance -
    // never reaches the poll loop, so surface it here rather than waiting a
    // tick for a session that will not change.
    if (session.status.isTerminal) {
      _lastErrorCode = session.error?.code;
      throw GeneralFailure(message: _messageFor(session));
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

  /// Drops one matched course from the list the review step is handed.
  ///
  /// Kept in [courses] so [excludedCourses] can still name it; only the
  /// selection loses it.
  void remove(SiakCourseModel course) {
    if (_selected.remove(course)) {
      autoFillRM.notify();
    }
  }

  /// [remove] by local `Course.id`, for callers holding a `CourseModel` that
  /// was mapped out of this state rather than the [SiakCourseModel] itself.
  void removeById(int? id) {
    if (id == null) {
      return;
    }
    final match = _selected.where((course) => course.id == id).toList();
    if (match.isEmpty) {
      return;
    }
    _selected.removeAll(match);
    autoFillRM.notify();
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
    // Echoed on every response. Held onto rather than overwritten blindly so a
    // payload that omits it cannot blank out a label already on screen.
    _givenSemester = session.givenSemester ?? _givenSemester;

    if (session.status == SlcmSessionStatus.ready ||
        session.status == SlcmSessionStatus.imported) {
      _preview = session.preview;
      final courses = _mapMatched(session.preview);
      _courses = courses;
      _duplicates = _mapDuplicates(session.preview);
      // Everything SLCM matched starts kept; [remove] takes rows back out.
      _selected
        ..clear()
        ..addAll(courses);
      _succeed();
      return;
    }

    if (session.status.isTerminal) {
      _lastErrorCode = session.error?.code;
      _failWith(GeneralFailure(message: _messageFor(session)));
      return;
    }

    // Still authenticating or still reading the IRS page. Notify so the
    // waiting view can say which of the two it is.
    autoFillRM.notify();
  }

  List<SiakCourseModel> _mapMatched(SlcmPreviewModel? preview) {
    return _mapPreviewCourses(preview?.matched);
  }

  List<SiakCourseModel> _mapDuplicates(SlcmPreviewModel? preview) {
    return _mapPreviewCourses(preview?.duplicates);
  }

  /// `matched` and `duplicates` carry the same shape, so one mapping serves
  /// both.
  List<SiakCourseModel> _mapPreviewCourses(
    List<SlcmPreviewCourseModel>? preview,
  ) {
    final courses = preview ?? const <SlcmPreviewCourseModel>[];
    return courses
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

  /// Copy for a settled-but-unsuccessful session.
  ///
  /// The known [SlcmErrorCode]s win over the backend's own `error.message`:
  /// those strings are operator-facing and the product owns what the student
  /// reads. An unrecognised code still falls through to the backend message,
  /// so a newly added failure is never flattened into the generic line.
  String _messageFor(SlcmSessionModel session) {
    final mapped = SlcmErrorCode.messageFor(session.error?.code);
    if (mapped != null) {
      return mapped;
    }
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
      case SlcmSessionStatus.authenticating:
      case SlcmSessionStatus.scraping:
      case SlcmSessionStatus.ready:
      case SlcmSessionStatus.imported:
      case SlcmSessionStatus.unknown:
        return 'Gagal mengambil data dari SLCM.';
    }
  }

  void _succeed() {
    _stopPolling();
    final settled = _settled;
    if (settled != null && !settled.isCompleted) {
      settled.complete();
    }
    autoFillRM.notify();
  }

  void _failWith(Failure failure) {
    _stopPolling();
    final settled = _settled;
    if (settled != null && !settled.isCompleted) {
      settled.completeError(failure);
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
  }

  void _reset() {
    _stopPolling();
    _settled = null;
    _lastErrorCode = null;
    _courses = null;
    _duplicates = null;
    _selected.clear();
    _givenSemester = null;
    _sessionId = null;
    _preview = null;
    _status = SlcmSessionStatus.unknown;
  }
}
