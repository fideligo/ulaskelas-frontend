part of '_widgets.dart';

/// Purple header of the component page: the grade being chased, the grade
/// earned so far, and the pills that switch the target.
class CardTargetGrade extends StatelessWidget {
  const CardTargetGrade({
    required this.target,
    required this.currentGrade,
    required this.currentScore,
    super.key,
    this.onTargetSelected,
  });

  final GradeTarget target;

  /// Letter for the score earned so far, e.g. `C+`.
  final String currentGrade;

  final double currentScore;

  final void Function(GradeTarget)? onTargetSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF44309F), Color(0xFF5C48D6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/ruby/ruby_smile.png', height: 34),
              const WidthSpace(8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Target grade Ruby',
                    style: FontTheme.poppins12w600black().copyWith(
                      color: BaseColors.white,
                    ),
                  ),
                ),
              ),
              _buildCurrentScore(),
            ],
          ),
          const HeightSpace(6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(target.label, style: FontTheme.poppins32w700white()),
              const WidthSpace(6),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '(${target.formattedScore})',
                  style: FontTheme.poppins14w500white().copyWith(
                    color: BaseColors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
          const HeightSpace(12),
          _buildTargetPills(),
        ],
      ),
    );
  }

  Widget _buildCurrentScore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Nilai saat ini',
          style: FontTheme.poppins10w500white().copyWith(
            color: BaseColors.white.withOpacity(0.85),
          ),
        ),
        const HeightSpace(2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currentGrade, style: FontTheme.poppins20w700white()),
            const WidthSpace(4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                currentScore.toStringAsFixed(2),
                style: FontTheme.poppins12w500white(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetPills() {
    return Row(
      children: GradeTarget.values.map((option) {
        final isSelected = option == target;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onTargetSelected?.call(option),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BaseColors.white
                      : BaseColors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    option.label,
                    style: FontTheme.poppins12w600black().copyWith(
                      color: isSelected
                          ? BaseColors.purpleHearth
                          : BaseColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
