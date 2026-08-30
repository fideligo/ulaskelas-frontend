/// Models for the SLCM autofill session API.
///
/// The backend runs one shared Chromium behind a noVNC popup: the app opens a
/// session, sends the student to `popupUrl` to log into SLCM by hand, polls the
/// session until the scraper reports `ready`, then confirms the import. Shapes
/// here mirror `views_slcm_autofill.py::_serialize` exactly.
library;

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

List<T> _asModelList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) build,
) {
  if (raw is! List) {
    return <T>[];
  }
  return raw.whereType<Map<String, dynamic>>().map(build).toList();
}

/// Lifecycle of a session, mirroring `SLCMAutofillSession.Status`.
///
/// [unknown] absorbs any state this build has not been taught about, so a
/// backend that gains a status stalls the poller instead of throwing mid-parse.
enum SlcmSessionStatus {
  waitingLogin('waiting_login'),
  scraping('scraping'),
  ready('ready'),
  imported('imported'),
  failed('failed'),
  expired('expired'),
  cancelled('cancelled'),
  unknown('');

  const SlcmSessionStatus(this.wire);

  /// The string the backend sends.
  final String wire;

  static SlcmSessionStatus fromWire(dynamic value) {
    for (final status in SlcmSessionStatus.values) {
      if (status.wire == value) {
        return status;
      }
    }
    return SlcmSessionStatus.unknown;
  }

  /// The scraper is still working — keep polling.
  bool get isPending =>
      this == SlcmSessionStatus.waitingLogin ||
      this == SlcmSessionStatus.scraping;

  /// Nothing will change on its own from here — stop polling.
  bool get isTerminal =>
      this == SlcmSessionStatus.imported ||
      this == SlcmSessionStatus.failed ||
      this == SlcmSessionStatus.expired ||
      this == SlcmSessionStatus.cancelled;
}

/// A course the scraper resolved against the local catalog.
///
/// Used for both `matched` and `duplicates`; the two lists carry the same
/// shape and differ only in whether the course is already in the semester.
class SlcmPreviewCourseModel {
  SlcmPreviewCourseModel({
    this.id,
    this.code,
    this.name,
    this.sks,
  });

  SlcmPreviewCourseModel.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    code = json['code'] as String?;
    name = json['name'] as String?;
    sks = _asInt(json['sks']);
  }

  /// Local `Course.id` — this is what the import runs on.
  int? id;
  String? code;
  String? name;
  int? sks;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'sks': sks,
    };
  }
}

/// A row scraped off the IRS page that no local course matched.
///
/// Shaped by the scraper, not the course table, so it has no id and spells the
/// credit count `credits` where a resolved course says `sks`. Informational
/// only: the import never touches these.
class SlcmUnmatchedCourseModel {
  SlcmUnmatchedCourseModel({
    this.code,
    this.name,
    this.credits,
  });

  SlcmUnmatchedCourseModel.fromJson(Map<String, dynamic> json) {
    code = json['code'] as String?;
    name = json['name'] as String?;
    credits = _asInt(json['credits']);
  }

  String? code;
  String? name;
  int? credits;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'credits': credits,
    };
  }
}

/// What the scraper found, present only once the session reaches `ready`
/// (and still present at `imported`); null in every other state.
class SlcmPreviewModel {
  SlcmPreviewModel({
    this.matched = const [],
    this.duplicates = const [],
    this.unmatched = const [],
  });

  SlcmPreviewModel.fromJson(Map<String, dynamic> json) {
    matched = _asModelList(json['matched'], SlcmPreviewCourseModel.fromJson);
    duplicates =
        _asModelList(json['duplicates'], SlcmPreviewCourseModel.fromJson);
    unmatched =
        _asModelList(json['unmatched'], SlcmUnmatchedCourseModel.fromJson);
  }

  /// Courses that will be imported on confirm.
  List<SlcmPreviewCourseModel> matched = const [];

  /// Already in this semester's calculator; the import skips them.
  List<SlcmPreviewCourseModel> duplicates = const [];

  /// Scraped but absent from the catalog; nothing can be imported for them.
  List<SlcmUnmatchedCourseModel> unmatched = const [];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'matched': matched.map((e) => e.toJson()).toList(),
      'duplicates': duplicates.map((e) => e.toJson()).toList(),
      'unmatched': unmatched.map((e) => e.toJson()).toList(),
    };
  }
}

/// Why a session failed, e.g. `LOGIN_TIMEOUT` or `BROWSER_ERROR`.
class SlcmSessionErrorModel {
  SlcmSessionErrorModel({this.code, this.message});

  SlcmSessionErrorModel.fromJson(Map<String, dynamic> json) {
    code = json['code'] as String?;
    message = json['message'] as String?;
  }

  String? code;
  String? message;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'message': message,
    };
  }
}

/// Counts returned by the confirm call. Present only on that response.
class SlcmImportResultModel {
  SlcmImportResultModel({this.inserted, this.duplicates});

  SlcmImportResultModel.fromJson(Map<String, dynamic> json) {
    inserted = _asInt(json['inserted']);
    duplicates = _asInt(json['duplicates']);
  }

  int? inserted;
  int? duplicates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inserted': inserted,
      'duplicates': duplicates,
    };
  }
}

/// An SLCM autofill session.
///
/// The same object comes back from create, poll, and confirm; the extra fields
/// are call-specific. [popupUrl] is only serialised on create, and [result]
/// only on confirm.
class SlcmSessionModel {
  SlcmSessionModel({
    this.sessionId,
    this.givenSemester,
    this.status = SlcmSessionStatus.unknown,
    this.expiresAt,
    this.sourcePeriod,
    this.preview,
    this.error,
    this.popupUrl,
    this.result,
  });

  SlcmSessionModel.fromJson(Map<String, dynamic> json) {
    sessionId = json['session_id'] as String?;
    givenSemester = json['given_semester'] as String?;
    status = SlcmSessionStatus.fromWire(json['status']);
    final rawExpiresAt = json['expires_at'];
    expiresAt = rawExpiresAt is String ? DateTime.tryParse(rawExpiresAt) : null;
    sourcePeriod = json['source_period'] as String?;
    final rawPreview = json['preview'];
    if (rawPreview is Map<String, dynamic>) {
      preview = SlcmPreviewModel.fromJson(rawPreview);
    }
    final rawError = json['error'];
    if (rawError is Map<String, dynamic>) {
      error = SlcmSessionErrorModel.fromJson(rawError);
    }
    popupUrl = json['popup_url'] as String?;
    final rawResult = json['result'];
    if (rawResult is Map<String, dynamic>) {
      result = SlcmImportResultModel.fromJson(rawResult);
    }
  }

  /// UUID string. Every other call in the flow is keyed on it.
  String? sessionId;

  /// The semester being filled, as the backend resolved it.
  ///
  /// The app no longer sends one: `createSession` posts an empty body and the
  /// backend derives the student's current semester from their NPM entry year
  /// and the running UI academic period, then echoes it here on the create
  /// response and on every poll. This is the only place the semester comes
  /// from now, so the review and confirmation screens label themselves off it.
  ///
  /// A string, not a number — the backend caps it at 20 characters and answers
  /// `INVALID_SEMESTER` for anything else. Null only if the field is missing
  /// from a response, which the display helpers fall back for.
  String? givenSemester;

  SlcmSessionStatus status = SlcmSessionStatus.unknown;

  /// When the session times out; the backend expires it server-side too.
  DateTime? expiresAt;

  /// The academic period the scraper actually read, e.g. `2025/2026 Ganjil`.
  String? sourcePeriod;

  SlcmPreviewModel? preview;
  SlcmSessionErrorModel? error;

  /// Where to send the student to log into SLCM. Create response only, and it
  /// is single-use — opening it twice returns `INVALID_POPUP_TOKEN`.
  String? popupUrl;

  /// Import counts. Confirm response only.
  SlcmImportResultModel? result;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session_id': sessionId,
      'given_semester': givenSemester,
      'status': status.wire,
      'expires_at': expiresAt?.toIso8601String(),
      'source_period': sourcePeriod,
      'preview': preview?.toJson(),
      'error': error?.toJson(),
      'popup_url': popupUrl,
      'result': result?.toJson(),
    };
  }
}
