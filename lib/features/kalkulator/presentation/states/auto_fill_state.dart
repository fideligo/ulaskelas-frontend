part of '_states.dart';

/// Courses SIAK reports for one semester, and which of them the student still
/// takes.
///
/// The SIAK scrape has no endpoint yet, so [retrieveData] serves the mock in
/// [_mockSiakCourses]. Swapping in the real call should only mean replacing
/// that one method with a repository call.
class AutoFillState implements FutureState<AutoFillState, String> {
  List<SiakCourseModel>? _courses;

  /// Held by identity rather than course code so a duplicated code in the
  /// real SIAK response cannot make two rows toggle together.
  final Set<SiakCourseModel> _selected = {};

  String? _givenSemester;

  List<SiakCourseModel> get courses => _courses ?? [];

  String? get givenSemester => _givenSemester;

  /// How many courses SIAK returned. Fixed once loaded — unchecking a row
  /// never changes what was *found*.
  int get totalFound => courses.length;

  int get selectedCount => _selected.length;

  /// Still in SIAK's order, not selection order.
  List<SiakCourseModel> get selectedCourses =>
      courses.where(_selected.contains).toList();

  bool isSelected(SiakCourseModel course) => _selected.contains(course);

  @override
  String? cacheKey = 'auto-fill-state';

  @override
  bool getCondition() => _courses?.isNotEmpty ?? false;

  @override
  Future<void> retrieveData(String givenSemester) async {
    _givenSemester = givenSemester;

    // Stands in for the round trip to SIAK so the waiting state is exercised.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _courses = _mockSiakCourses();
    // Everything on the IRS is taken by default; the student only unchecks
    // what they dropped.
    _selected
      ..clear()
      ..addAll(_courses!);

    autoFillRM.notify();
  }

  void toggle(SiakCourseModel course) {
    if (!_selected.remove(course)) {
      _selected.add(course);
    }
    autoFillRM.notify();
  }

  List<SiakCourseModel> _mockSiakCourses() {
    return [
      SiakCourseModel(
        name: 'Basis Data',
        code: 'CSGE602070',
        sks: 4,
        type: 'Wajib',
      ),
      SiakCourseModel(
        name: 'Struktur Data dan Algoritma',
        code: 'CSGE601020',
        sks: 4,
        type: 'Wajib',
      ),
      SiakCourseModel(
        name: 'Game Development',
        code: 'CSGE603140',
        sks: 3,
        type: 'Pilihan',
      ),
      SiakCourseModel(
        name: 'Jarkom & Keamanan',
        code: 'CSGE602022',
        sks: 4,
        type: 'Wajib',
      ),
      SiakCourseModel(
        name: 'Forensik Digital',
        code: 'CSCE604234',
        sks: 4,
        type: 'Wajib',
      ),
      SiakCourseModel(
        name: 'Analisis Numerik',
        code: 'CSCM601252',
        sks: 3,
        type: 'Pilihan',
      ),
    ];
  }
}
