part of '_pages.dart';

/// Placeholder for the review step that will confirm and save the semester.
///
/// Lists what was carried over so the selection can be checked before the
/// real review screen exists.
class ConfirmSemesterPage extends StatelessWidget {
  const ConfirmSemesterPage({
    required this.givenSemester,
    required this.courses,
    super.key,
  });

  final String givenSemester;
  final List<SiakCourseModel> courses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseColors.white,
      appBar: BaseAppBar(
        label: 'Review Semester',
        centerTitle: false,
        elevation: 0,
        style: FontTheme.poppins18w700black(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: BaseColors.purpleHearth.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semesterFullLabel(givenSemester),
                    style: FontTheme.poppins14w600black().copyWith(
                      color: BaseColors.purpleHearth,
                    ),
                  ),
                  const HeightSpace(2),
                  Text(
                    '${courses.length} matkul dipilih',
                    style: FontTheme.poppins12w500black().copyWith(
                      color: BaseColors.purpleHearth.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const HeightSpace(18),
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '• ${course.name} (${course.sks} SKS · ${course.code})',
                  style: FontTheme.poppins12w400black(),
                ),
              ),
            ),
            const HeightSpace(10),
            Text(
              'Penyimpanan semester belum tersedia.',
              style: FontTheme.poppins12w400black().copyWith(
                color: BaseColors.gray2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
