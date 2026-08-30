part of '_widgets.dart';

/// A course inside the active semester, with the badge that says how far its
/// grade components have been filled in.
class CardActiveCourse extends StatelessWidget {
  const CardActiveCourse({
    required this.model,
    required this.status,
    super.key,
    this.facultyName,
    this.onTap,
  });

  final CalculatorModel model;
  final CourseStatus status;

  /// Retained so existing call sites keep compiling; [FacultyLogo] resolves
  /// the crest from the course code exclusively and never reads this.
  final String? facultyName;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: BaseColors.white,
          boxShadow: BoxShadowDecorator().defaultShadow(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            FacultyLogo(
              code: model.courseCode,
              facultyName: facultyName,
            ),
            const WidthSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.courseName ?? '-',
                    style: FontTheme.poppins14w600black(),
                  ),
                  const HeightSpace(3),
                  _subtitle(),
                ],
              ),
            ),
            const WidthSpace(12),
            Text(
              status.grade,
              style: FontTheme.poppins16w700black().copyWith(
                color: status.isComplete
                    ? BaseColors.success
                    : BaseColors.gray3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `4 SKS · nilai lengkap`, with a warning triangle when the rubric is
  /// still missing weight.
  Widget _subtitle() {
    final statusColor =
        status.isComplete ? BaseColors.success : BaseColors.gray2;

    return Row(
      children: [
        Flexible(
          child: Text(
            '${model.courseSKS ?? 0} SKS · ',
            style: FontTheme.poppins12w400black().copyWith(
              color: BaseColors.gray2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (status.hasWarning) ...[
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: BaseColors.warning,
          ),
          const WidthSpace(3),
        ],
        Flexible(
          child: Text(
            status.label,
            style: FontTheme.poppins12w400black().copyWith(color: statusColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
