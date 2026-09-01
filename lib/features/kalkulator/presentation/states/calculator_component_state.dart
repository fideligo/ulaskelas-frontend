part of '_states.dart';

/// Backs the revamped course component detail page.
///
/// Everything on screen comes from the API: components and their weights from
/// `/api/course-component`, the per-occurrence scores from
/// `/api/course-subcomponent`, and Ruby's recommendation from the same
/// component call — the backend recalculates it whenever the target changes.
class CalculatorComponentState
    implements FutureState<CalculatorComponentState, QueryComponent> {
  CalculatorComponentState() {
    _repo = ComponentRepositoryImpl(ComponentRemoteDataSourceImpl());
    _courseRepo = CourseRepositoryImpl(
      CourseRemoteDataSourceImpl(),
      CourseLocalDataSourceImpl(),
    );
  }

  late ComponentRepository _repo;
  late CourseRepository _courseRepo;

  List<ComponentBreakdown>? _breakdowns;

  /// Ids of the cards the user has opened.
  final Set<int> _expanded = {};

  GradeTarget target = GradeTarget.a;

  /// Ruby's recommended score for the occurrences still empty, straight from
  /// the API.
  double recommendedScore = 0;

  double maxPossibleScore = 100;

  /// Course type pill, e.g. `Wajib Fakultas`. Stays null when the course
  /// endpoint has nothing for it, and the pill is then left off.
  String? courseType;

  List<ComponentBreakdown> get breakdowns => _breakdowns ?? [];

  double get totalWeight =>
      breakdowns.fold(0, (sum, breakdown) => sum + breakdown.weight);

  /// The recommendation UI only makes sense once the weights add up.
  bool get hasFullWeight => totalWeight >= 100;

  /// Each component's filled average against its weight.
  double get currentScore =>
      breakdowns.fold(0, (sum, breakdown) => sum + breakdown.weightedScore);

  String get currentGrade => getFinalGrade(currentScore);

  bool get allFilled =>
      breakdowns.isNotEmpty && breakdowns.every((b) => b.isFullyFilled);

  bool isExpanded(ComponentBreakdown breakdown) =>
      _expanded.contains(breakdown.id);

  @override
  String? cacheKey = 'calculator-component-state';

  @override
  bool getCondition() => _breakdowns?.isNotEmpty ?? false;

  @override
  Future<void> retrieveData(QueryComponent query) async {
    // Asking for the target up front keeps the datasource from firing a
    // second request to lower it for us.
    query.targetScore = target.minimumScore;

    final resp = await _repo.getAllComponent(query);
    resp.fold((failure) => throw failure, (result) {
      final components = result.data['components'] as List<ComponentModel>;
      recommendedScore =
          (result.data['recommended_score'] as num?)?.toDouble() ?? 0;
      maxPossibleScore =
          (result.data['max_possible_score'] as num?)?.toDouble() ?? 100;
      _breakdowns =
          components.map(ComponentBreakdown.fromComponentOnly).toList();
    });

    await _loadOccurrences();
    calculatorComponentRM.notify();
  }

  /// Refetches so the backend can recompute [recommendedScore] for the new
  /// target.
  Future<void> changeTarget(GradeTarget newTarget, int calculatorId) async {
    if (newTarget == target) {
      return;
    }
    target = newTarget;
    await retrieveData(QueryComponent(calculatorId: calculatorId));
  }

  void toggleExpanded(ComponentBreakdown breakdown) {
    if (!_expanded.remove(breakdown.id)) {
      _expanded.add(breakdown.id);
    }
    calculatorComponentRM.notify();
  }

  /// The type shown in the header pills lives on the course, not the
  /// calculator, so it takes its own call.
  Future<void> loadCourseType(int courseId) async {
    final resp = await _courseRepo.getDetailCourse(courseId);
    resp.fold((failure) => null, (result) {
      courseType = courseTypeLabel(result.data.codeDesc, result.data.code);
    });
    calculatorComponentRM.notify();
  }

  /// Ruby's number for a row: an occurrence already graded shows what it
  /// scored, an empty one shows what it still needs.
  ///
  /// Null across the board until the weights add up — a target computed
  /// against a partial rubric would be wrong, so the column shows `-` rather
  /// than a number the student might act on.
  double? recommendationFor({required double? score}) {
    if (!hasFullWeight) {
      return null;
    }
    return score ?? recommendedScore;
  }

  /// The component list has no per-occurrence scores, so each component needs
  /// its own call. A component that fails keeps the single-occurrence
  /// fallback rather than blanking the page.
  Future<void> _loadOccurrences() async {
    _breakdowns = await Future.wait(breakdowns.map(_loadOccurrence));
  }

  Future<ComponentBreakdown> _loadOccurrence(
    ComponentBreakdown fallback,
  ) async {
    final resp = await _repo.getDetailComponent(
      QueryComponent(scoreComponentId: fallback.id),
    );

    return resp.fold(
      (failure) => fallback,
      (result) {
        final raw = result.data['scores'] as List?;
        if (raw == null || raw.isEmpty) {
          return fallback;
        }
        return ComponentBreakdown(
          component: fallback.component,
          scores: raw.map((score) => (score as num?)?.toDouble()).toList(),
        );
      },
    );
  }
}
