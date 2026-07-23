part of '_widgets.dart';

/// Column widths shared by the table header and every component row, so the
/// four columns stay lined up.
class _ComponentColumns {
  static const name = 36;
  static const score = 20;
  static const weight = 16;

  /// Widest of the numeric columns — `Rek. Ruby` must not wrap.
  static const recommendation = 28;

  /// Room for the chevron at the end of a row; the header pads to match.
  static const chevronWidth = 18.0;
}

/// `Komponen | Nilai | Bobot | Rek. Ruby` above the component list.
class ComponentTableHeader extends StatelessWidget {
  const ComponentTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = FontTheme.poppins12w600black();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            flex: _ComponentColumns.name,
            child: Text('Komponen', style: style),
          ),
          Expanded(
            flex: _ComponentColumns.score,
            child: Text('Nilai', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: _ComponentColumns.weight,
            child: Text('Bobot', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: _ComponentColumns.recommendation,
            child: Text(
              'Rek. Ruby',
              style: style.copyWith(color: BaseColors.purpleHearth),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: _ComponentColumns.chevronWidth),
        ],
      ),
    );
  }
}

/// One component, expanding to show the individual occurrences behind it.
class CardComponentExpansion extends StatelessWidget {
  const CardComponentExpansion({
    required this.breakdown,
    required this.isExpanded,
    required this.recommendation,
    super.key,
    this.occurrenceRecommendation,
    this.rubyEnabled = true,
    this.onTap,
    this.onEdit,
  });

  final ComponentBreakdown breakdown;
  final bool isExpanded;

  /// Ruby's number for the component as a whole; null hides the column.
  final double? recommendation;

  /// Ruby's number for a single empty occurrence.
  final double? occurrenceRecommendation;

  /// False while the rubric is under 100%, which blanks the `Rek. Ruby`
  /// column on the expanded occurrence rows too — otherwise a graded
  /// occurrence would keep showing a number while its component shows `-`.
  final bool rubyEnabled;

  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BaseColors.white,
        boxShadow: BoxShadowDecorator().defaultShadow(context),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: _buildSummaryRow(),
            ),
          ),
          if (isExpanded) _buildOccurrences(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final average = breakdown.average;
    // A component still missing scores is called out in amber.
    final isIncomplete = !breakdown.isFullyFilled;

    return Row(
      children: [
        Expanded(
          flex: _ComponentColumns.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(breakdown.name, style: FontTheme.poppins12w600black()),
              const HeightSpace(2),
              Text(
                '${breakdown.filledCount}/${breakdown.totalCount} terisi',
                style: FontTheme.poppins10w400black().copyWith(
                  color: isIncomplete ? BaseColors.warning : BaseColors.gray2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: _ComponentColumns.score,
          child: Text(
            average?.toStringAsFixed(2) ?? 'Kosong',
            textAlign: TextAlign.right,
            style: FontTheme.poppins12w500black().copyWith(
              color: average == null
                  ? BaseColors.gray3
                  : (isIncomplete ? BaseColors.warning : BaseColors.mineShaft),
            ),
          ),
        ),
        Expanded(
          flex: _ComponentColumns.weight,
          child: Text(
            '${formatDouble(breakdown.weight)}%',
            textAlign: TextAlign.right,
            style: FontTheme.poppins12w500black(),
          ),
        ),
        Expanded(
          flex: _ComponentColumns.recommendation,
          child: Text(
            recommendation?.toStringAsFixed(2) ?? '-',
            textAlign: TextAlign.right,
            style: FontTheme.poppins12w500black().copyWith(
              // Purple only when it is a recommendation rather than a score
              // the student already has.
              color: breakdown.isFullyFilled
                  ? BaseColors.mineShaft
                  : BaseColors.purpleHearth,
            ),
          ),
        ),
        SizedBox(
          width: _ComponentColumns.chevronWidth,
          child: Icon(
            isExpanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.arrow_forward_ios_rounded,
            size: isExpanded ? 18 : 11,
            color: BaseColors.gray3,
          ),
        ),
      ],
    );
  }

  Widget _buildOccurrences() {
    return Container(
      color: BaseColors.neutral20,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Column(
        children: [
          for (var index = 0; index < breakdown.totalCount; index++)
            _buildOccurrenceRow(index),
          if (onEdit != null)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Edit Komponen',
                    style: FontTheme.poppins12w600black().copyWith(
                      color: BaseColors.purpleHearth,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceRow(int index) {
    final score = breakdown.scores[index];
    final shown = rubyEnabled ? score ?? occurrenceRecommendation : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: _ComponentColumns.name,
            child: Text(
              breakdown.occurrenceName(index),
              style: FontTheme.poppins12w500black(),
            ),
          ),
          Expanded(
            flex: _ComponentColumns.score,
            child: Text(
              score?.toStringAsFixed(2) ?? 'Kosong',
              textAlign: TextAlign.right,
              style: FontTheme.poppins12w500black().copyWith(
                color: score == null ? BaseColors.gray3 : BaseColors.mineShaft,
              ),
            ),
          ),
          Expanded(
            flex: _ComponentColumns.weight,
            child: Text(
              '${formatDouble(breakdown.weightPerOccurrence)}%',
              textAlign: TextAlign.right,
              style: FontTheme.poppins12w500black(),
            ),
          ),
          Expanded(
            flex: _ComponentColumns.recommendation,
            child: Text(
              shown?.toStringAsFixed(2) ?? '-',
              textAlign: TextAlign.right,
              style: FontTheme.poppins12w500black().copyWith(
                color: score == null
                    ? BaseColors.purpleHearth
                    : BaseColors.mineShaft,
              ),
            ),
          ),
          const SizedBox(width: _ComponentColumns.chevronWidth),
        ],
      ),
    );
  }
}
