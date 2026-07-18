part of '_widgets.dart';

/// Tinted header that opens the semester currently in progress.
class CardActiveSemester extends StatelessWidget {
  const CardActiveSemester({
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
          color: BaseColors.purpleHearth.withOpacity(0.09),
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
                    style: FontTheme.poppins14w600black().copyWith(
                      color: BaseColors.purpleHearth,
                    ),
                  ),
                  const HeightSpace(2),
                  Text(
                    'IP: ${formatGpa(model.semesterGPA)}',
                    style: FontTheme.poppins12w500black().copyWith(
                      color: BaseColors.purpleHearth.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const WidthSpace(12),
            Text(
              'See details',
              style: FontTheme.poppins12w500black().copyWith(
                color: BaseColors.purpleHearth,
              ),
            ),
            const WidthSpace(4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: BaseColors.purpleHearth,
            ),
          ],
        ),
      ),
    );
  }
}
