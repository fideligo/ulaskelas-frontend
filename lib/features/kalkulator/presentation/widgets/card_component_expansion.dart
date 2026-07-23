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

/// Column widths for an expanded occurrence pill — three fields, not four:
/// there is no per-occurrence weight to show once the component's own row
/// already states it.
class _OccurrenceColumns {
  static const name = 40;
  static const score = 30;
  static const recommendation = 30;
}

/// Design-signed one-offs for the occurrence pill, pinned locally the same
/// way `komponen_bottom_sheet.dart` pins its own palette — the nearest
/// `BaseColors` tokens (`neutral20`, `gray3`) are close but not these exact
/// values, and drifting onto them silently would be wrong.
abstract class _OccurrenceColors {
  static const pillBackground = Color(0xFFF4F4F5);
  static const placeholder = Color(0xFF9CA3AF);
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
    final rows = <Widget>[];
    for (var index = 0; index < breakdown.totalCount; index++) {
      if (rows.isNotEmpty) {
        rows.add(const HeightSpace(8));
      }
      rows.add(_buildOccurrenceRow(index));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows,
          if (onEdit != null) ...[
            const HeightSpace(10),
            InkWell(
              onTap: onEdit,
              child: Text(
                'Edit Komponen',
                style: FontTheme.poppins12w600black().copyWith(
                  color: BaseColors.purpleHearth,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One occurrence pill: name, its score (or `Kosong`), and Ruby's number —
  /// no weight, since the parent row already states it once for the whole
  /// component.
  Widget _buildOccurrenceRow(int index) {
    final score = breakdown.scores[index];
    final shown = rubyEnabled ? score ?? occurrenceRecommendation : null;
    final isEmpty = score == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _OccurrenceColors.pillBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _OccurrenceColumns.name,
            child: Text(
              breakdown.occurrenceName(index),
              style: FontTheme.poppins12w600black(),
            ),
          ),
          Expanded(
            flex: _OccurrenceColumns.score,
            child: Text(
              score?.toStringAsFixed(2) ?? 'Kosong',
              textAlign: TextAlign.center,
              style: FontTheme.poppins12w500black().copyWith(
                color: isEmpty
                    ? _OccurrenceColors.placeholder
                    : BaseColors.mineShaft,
              ),
            ),
          ),
          Expanded(
            flex: _OccurrenceColumns.recommendation,
            child: Text(
              shown?.toStringAsFixed(2) ?? '-',
              textAlign: TextAlign.right,
              // Bold purple only while it's Ruby's prediction rather than a
              // score the student already has.
              style: (isEmpty
                      ? FontTheme.poppins12w700black()
                      : FontTheme.poppins12w500black())
                  .copyWith(
                color: isEmpty ? BaseColors.purpleHearth : BaseColors.mineShaft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
