part of '_states.dart';

/// Catalogue search for picking a semester's courses by hand.
///
/// Reads the real course endpoint through [CourseRepository] with the same
/// page-by-page loading the matkul search uses.
class ManualFillState
    implements FutureState<ManualFillState, QuerySearchCourse> {
  ManualFillState() {
    _repo = CourseRepositoryImpl(
      CourseRemoteDataSourceImpl(),
      CourseLocalDataSourceImpl(),
    );
  }

  late CourseRepository _repo;

  /// Owned here so the text survives rebuilds of the page.
  final controller = TextEditingController();

  List<CourseModel>? _courses;

  /// Keyed by course id rather than kept in a `Set<CourseModel>`: the model
  /// overrides `==` but leaves `hashCode` as identity, so a hash lookup would
  /// miss an equal course that came back from a later page or a new search —
  /// exactly when a selection has to survive.
  final Map<int, CourseModel> _selected = {};

  Timer? _debounce;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;
  int _page = 1;
  String _lastQuery = '';

  List<CourseModel> get courses => _courses ?? [];

  bool get hasReachedMax => _hasReachedMax;

  /// Drives the spinner under the list while the next page is in flight.
  bool get isLoadingMore => _isLoadingMore;

  int get selectedCount => _selected.length;

  List<CourseModel> get selectedCourses => _selected.values.toList();

  bool isSelected(CourseModel course) => _selected.containsKey(course.id);

  @override
  String? cacheKey = 'manual-fill-state';

  @override
  bool getCondition() => _courses?.isNotEmpty ?? false;

  @override
  Future<void> retrieveData(QuerySearchCourse query) async {
    _page = 1;
    query.page = 1;

    final resp = await _repo.getAllCourse(query);
    resp.fold((failure) => throw failure, (result) {
      _hasReachedMax = result.data.length < query.limit;
      _courses = _sortedByName(result.data);
    });

    manualFillRM.notify();
  }

  /// Appends the next page. Failures are kept quiet on purpose — the list on
  /// screen is still valid, and blanking it because a scroll-triggered fetch
  /// failed would lose the user's selections.
  Future<void> retrieveMoreData(QuerySearchCourse query) async {
    if (_hasReachedMax || _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;
    manualFillRM.notify();

    _page++;
    query.page = _page;

    final resp = await _repo.getAllCourse(query);
    resp.fold(
      (failure) {
        // Step back so the same page is retried on the next scroll.
        _page--;
      },
      (result) {
        _hasReachedMax = result.data.length < query.limit;
        _courses = _sortedByName(_withoutDuplicates(result.data));
      },
    );

    _isLoadingMore = false;
    manualFillRM.notify();
  }

  /// Refetches from page 1 once typing settles.
  void onQueryChanged(String value) {
    if (value == _lastQuery) {
      return;
    }
    _lastQuery = value;
    manualFillRM.notify();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _hasReachedMax = false;
      manualFillRM.setState(
        (s) => s.retrieveData(QuerySearchCourse(name: value)),
      );
    });
  }

  void toggle(CourseModel course) {
    final id = course.id;
    if (id == null) {
      return;
    }
    if (_selected.remove(id) == null) {
      _selected[id] = course;
    }
    manualFillRM.notify();
  }

  void unselect(CourseModel course) {
    _selected.remove(course.id);
    manualFillRM.notify();
  }

  /// Entering the page starts from a clean search and an empty basket.
  void reset() {
    _debounce?.cancel();
    controller.clear();
    _selected.clear();
    _courses = null;
    _hasReachedMax = false;
    _isLoadingMore = false;
    _page = 1;
    _lastQuery = '';
  }

  List<CourseModel> _withoutDuplicates(List<CourseModel> incoming) {
    final merged = [...courses];
    for (final course in incoming) {
      if (!merged.any((existing) => existing.id == course.id)) {
        merged.add(course);
      }
    }
    return merged;
  }

  /// The endpoint returns its own order; the design asks for A-Z.
  List<CourseModel> _sortedByName(List<CourseModel> courses) {
    return [...courses]..sort(
        (a, b) => (a.name ?? '').toLowerCase().compareTo(
              (b.name ?? '').toLowerCase(),
            ),
      );
  }
}
