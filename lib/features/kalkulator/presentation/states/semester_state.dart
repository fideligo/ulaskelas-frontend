part of '_states.dart';

class SemesterState implements FutureState<SemesterState, void> {
  SemesterState() {
    _repo = SemesterRepositoryImpl(SemesterRemoteDataSourceImpl());
    _calculatorRepo = CalculatorRepositoryImpl(
      CalculatorRemoteDataSourceImpl(),
    );
    _componentRepo = ComponentRepositoryImpl(ComponentRemoteDataSourceImpl());
  }

  late SemesterRepository _repo;
  late CalculatorRepository _calculatorRepo;
  late ComponentRepository _componentRepo;

  List<SemesterModel>? _semesters;
  List<SemesterModel>? _autoFillSemesters;
  List<SemesterModel> _sortedSemesters = [];

  /// Courses of [activeSemester] only — the home page never lists the courses
  /// of a past semester.
  List<CalculatorModel>? _activeCourses;

  /// Status badge per calculator id, filled in by [_loadCourseStatus].
  final Map<int, CourseStatus> _courseStatuses = {};

  /// Hides the cumulative GPA behind `****`, the way a banking app hides a
  /// balance. Local to the session, never persisted.
  bool isGpaHidden = false;

  List<SemesterModel> get semesters => _semesters ?? [];
  List<SemesterModel> get autoFillSemesters => _autoFillSemesters ?? [];
  List<SemesterModel> get availableSemestersToFill =>
      (_semesters?.isEmpty ?? true)
          ? (_autoFillSemesters ?? [])
          : (_autoFillSemesters ?? []).where(
              (autoFillSemester) {
                return !semesters.any(
                  (semester) {
                    return semester.givenSemester ==
                        autoFillSemester.givenSemester;
                  },
                );
              },
            ).toList();

  /// Every semester, highest term first.
  List<SemesterModel> get sortedSemesters => _sortedSemesters;

  /// The semester with the highest term number, which is what the page treats
  /// as "sedang berjalan" — not the one that happens to be newest in the API
  /// response.
  SemesterModel? get activeSemester =>
      _sortedSemesters.isEmpty ? null : _sortedSemesters.first;

  /// Everything below [activeSemester], still highest term first.
  List<SemesterModel> get pastSemesters =>
      _sortedSemesters.isEmpty ? [] : _sortedSemesters.sublist(1);

  List<CalculatorModel> get activeCourses => _activeCourses ?? [];

  String get cumulativeGPA => _repo.gpa;

  /// The GPA as rendered on the card, masked when the user has hidden it.
  String get cumulativeGPADisplay =>
      isGpaHidden ? '****' : formatGpaString(cumulativeGPA);

  /// Badge on the IPK card, e.g. `Sem 6 Aktif` or `Sem SP 2025 Aktif`.
  String get activeSemesterBadge {
    final givenSemester = activeSemester?.givenSemester;
    if (givenSemester == null) {
      return '';
    }
    return 'Sem ${semesterShortLabel(givenSemester)} Aktif';
  }

  bool hasReachedMax = false;
  int page = 1;

  @override
  String? cacheKey = 'semester-state';

  @override
  bool getCondition() {
    return _semesters?.isNotEmpty ?? false;
  }

  /// Badge for [course], falling back to a weight-only verdict when the
  /// component breakdown could not be loaded.
  CourseStatus statusOf(CalculatorModel course) {
    final loaded = _courseStatuses[course.id];
    if (loaded != null) {
      return loaded;
    }
    return CourseStatus.evaluate(
      totalWeight: course.totalPercentage ?? 0,
      filledComponents: 0,
      totalComponents: 0,
      totalScore: course.totalScore ?? 0,
    );
  }

  void toggleGpaVisibility() {
    isGpaHidden = !isGpaHidden;
    semesterRM.notify();
  }

  @override
  Future<void> retrieveData([void _]) async {
    await _fetchSemesters();
    await _loadActiveSemesterCourses();
    semesterRM.notify();

    // For Showcase Purpose (new user)
    if (Pref.getBool('doneAppTour') == false ||
        Pref.getBool('doneAppTour') == null) {
      await showcaseEmptySemester();
    }
  }

  Future<void> postSemester(List<String> givenSemesters) async {
    final resp = await _repo.postSemester(givenSemesters);
    await resp.fold((failure) {
      ErrorMessenger('Data Semester tersebut sudah pernah dibuat').show(ctx!);
    }, (result) async {
      SuccessMessenger('Data Semester berhasil dibuat').show(ctx!);
      await _fetchSemesters();
      await _loadActiveSemesterCourses();
    });
    semesterRM.notify();
  }

  Future<void> deleteSemester({
    required QuerySemester query,
  }) async {
    final resp = await _repo.deleteSemester(query);
    await resp.fold((failure) {
      ErrorMessenger('Data Semester gagal dihapus').show(ctx!);
    }, (result) async {
      SuccessMessenger('Data Semester berhasil dihapus').show(ctx!);
      await _fetchSemesters();
      await _loadActiveSemesterCourses();
    });
    semesterRM.notify();
  }

  Future<void> retrieveDataForAutoFillSemesters() async {
    final resp = await _repo.getAutoFillSemester();

    resp.fold((failure) => throw failure, (result) {
      _autoFillSemesters = result.data;
    });
    semesterRM.notify();
  }

  Future<void> postAutoFillSemester(Map<String, dynamic> model) async {
    final resp = await _repo.postAutoFillSemester(model);
    await resp.fold((failure) {
      ErrorMessenger('Data Semester gagal dibuat').show(ctx!);
    }, (result) async {
      SuccessMessenger('Data Semester berhasil dibuat').show(ctx!);
      await _fetchSemesters();
      await _loadActiveSemesterCourses();

      semesterRM.notify();

      // For Showcase Purpose (new user)
      if (Pref.getBool('doneAppTour') == false ||
          Pref.getBool('doneAppTour') == null) {
        await showcaseFilledSemester();
      }
    });
  }

  Future<void> _fetchSemesters() async {
    final resp = await _repo.getSemesters();
    resp.fold((failure) => throw failure, (result) {
      final lessThanLimit = result.data.length < 10;
      hasReachedMax = result.data.isEmpty || lessThanLimit;
      _semesters = result.data;
      _sortedSemesters = [...result.data]
        ..sort((a, b) => _rankOf(b).compareTo(_rankOf(a)));
    });
  }

  Future<void> _loadActiveSemesterCourses() async {
    _activeCourses = [];
    _courseStatuses.clear();

    final givenSemester = activeSemester?.givenSemester;
    if (givenSemester == null) {
      return;
    }

    final resp = await _calculatorRepo.getAllCalculator(givenSemester);
    resp.fold((failure) => throw failure, (result) {
      _activeCourses = result.data;
    });

    await Future.wait(activeCourses.map(_loadCourseStatus));
  }

  /// The course list endpoint has no component breakdown, so `3/6 nilai diisi`
  /// costs one extra call per course. They run together and a failure is
  /// swallowed on purpose: [statusOf] still has the weight from the course
  /// list to fall back on, so one bad response cannot blank the page.
  Future<void> _loadCourseStatus(CalculatorModel course) async {
    final calculatorId = course.id;
    if (calculatorId == null) {
      return;
    }

    final resp = await _componentRepo.getComponentSummary(calculatorId);
    resp.fold((failure) => null, (result) {
      _courseStatuses[calculatorId] = CourseStatus.evaluate(
        totalWeight: result.data['total_weight'] as double,
        filledComponents: result.data['filled'] as int,
        totalComponents: result.data['total'] as int,
        totalScore: course.totalScore ?? 0,
      );
    });
  }

  double _rankOf(SemesterModel semester) =>
      semesterRank(semester.givenSemester ?? '', _userGeneration);

  int get _userGeneration =>
      int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;
}
