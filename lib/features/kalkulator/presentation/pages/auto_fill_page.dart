part of '_pages.dart';

/// Placeholder for the SIAK auto-fill flow.
///
/// Only proves the semester picked on [AddSemesterPage] arrives intact; the
/// import itself is a later story.
class AutoFillPage extends StatelessWidget {
  const AutoFillPage({
    required this.givenSemester,
    super.key,
  });

  final String givenSemester;

  @override
  Widget build(BuildContext context) {
    return FillMethodPlaceholder(
      title: 'Auto-Fill dari SIAK',
      givenSemester: givenSemester,
      message: 'Impor matkul dari SIAK belum tersedia.',
    );
  }
}
