/// The grades Ruby can aim for, best first.
enum GradeTarget {
  a('A', 85),
  aMinus('A-', 80),
  bPlus('B+', 75),
  b('B', 70),
  bMinus('B-', 65),
  cPlus('C+', 60),
  c('C', 55);

  const GradeTarget(this.label, this.minimumScore);

  /// Letter shown on the pill, e.g. `A-`.
  final String label;

  /// Lowest final score that still earns [label].
  final int minimumScore;

  /// `85.00`, as printed next to the big letter.
  String get formattedScore => minimumScore.toDouble().toStringAsFixed(2);

  /// Maps a score the API already knows about back onto a pill.
  static GradeTarget fromScore(int? score) {
    return values.firstWhere(
      (target) => target.minimumScore == score,
      orElse: () => GradeTarget.a,
    );
  }
}
