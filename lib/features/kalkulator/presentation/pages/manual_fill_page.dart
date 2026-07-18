part of '_pages.dart';

/// Placeholder for the manual course-picking flow.
///
/// Only proves the semester picked on [AddSemesterPage] arrives intact; the
/// multi-select itself is a later story.
class ManualFillPage extends StatelessWidget {
  const ManualFillPage({
    required this.givenSemester,
    super.key,
  });

  final String givenSemester;

  @override
  Widget build(BuildContext context) {
    return FillMethodPlaceholder(
      title: 'Pilih Matkul Manual',
      givenSemester: givenSemester,
      message: 'Pencarian dan multi-select matkul belum tersedia.',
    );
  }
}
