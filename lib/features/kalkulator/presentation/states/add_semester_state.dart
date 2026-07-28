part of '_states.dart';

/// Form state for the "Tambah Semester" screen: which semester the user picked
/// before choosing how to fill it.
class AddSemesterState {
  String? _selectedSemester;

  /// The `given_semester` id, e.g. `'6'` or `'sp_2026'`.
  String? get selectedSemester => _selectedSemester;

  /// What the dropdown shows once something is picked.
  String? get selectedSemesterLabel =>
      _selectedSemester == null ? null : semesterFullLabel(_selectedSemester!);

  bool get hasSelection => _selectedSemester != null;

  /// Every semester on offer, ordered for the dropdown.
  List<String> get options => semesterCatalogue(_userGeneration);

  /// Clear the previous pick so re-entering the page starts empty.
  void reset() {
    _selectedSemester = null;
    addSemesterRM.notify();
  }

  void select(String? givenSemester) {
    _selectedSemester = givenSemester;
    addSemesterRM.notify();
  }

  int get _userGeneration =>
      int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;
}
