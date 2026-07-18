part of '_widgets.dart';

/// A finished semester in the "Semester Lalu" list: name over its final IPS.
class CardPastSemester extends StatelessWidget {
  const CardPastSemester({
    required this.model,
    super.key,
    this.onTap,
  });

  final SemesterModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: BaseColors.white,
          boxShadow: BoxShadowDecorator().defaultShadow(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semesterFullLabel(model.givenSemester ?? ''),
                    style: FontTheme.poppins14w600black(),
                  ),
                  const HeightSpace(3),
                  Text(
                    formatGpa(model.semesterGPA),
                    style: FontTheme.poppins12w600black().copyWith(
                      color: BaseColors.purpleHearth,
                    ),
                  ),
                ],
              ),
            ),
            const WidthSpace(12),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: BaseColors.gray3,
            ),
          ],
        ),
      ),
    );
  }
}
