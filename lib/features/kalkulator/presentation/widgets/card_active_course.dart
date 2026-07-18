part of '_widgets.dart';

/// A course inside the active semester, with the badge that says how far its
/// grade components have been filled in.
class CardActiveCourse extends StatelessWidget {
  const CardActiveCourse({
    required this.model,
    required this.status,
    super.key,
    this.onTap,
  });

  final CalculatorModel model;
  final CourseStatus status;
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
            _avatar(),
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

  /// The design calls for a course logo, which neither the assets nor the
  /// course endpoint provide — initials on a tinted tile stand in for it.
  Widget _avatar() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: BaseColors.purpleHearth.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _initials,
          style: FontTheme.poppins14w700black().copyWith(
            color: BaseColors.purpleHearth,
          ),
        ),
      ),
    );
  }

  /// [CalculatorModel.shortName] is only filled in by `fromJson`, so derive it
  /// again for locally built models.
  String get _initials {
    final shortName = model.shortName;
    if (shortName != null && shortName.isNotEmpty) {
      return shortName.toUpperCase();
    }

    final words = (model.courseName ?? '')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2);
    if (words.isEmpty) {
      return '?';
    }
    return words.map((word) => word[0]).join().toUpperCase();
  }
}
