import 'package:ulaskelas/core/utils/util.dart';

/// Which of the three "status data matkul" tiers a course falls into.
enum CourseStatusKind {
  /// Weights add up and every component has a score.
  complete,

  /// The rubric itself is unfinished — weights total below 100%.
  missingWeight,

  /// Rubric is complete but some components have no score yet.
  missingScores,
}

/// The badge shown next to a course in the active semester list.
class CourseStatus {
  const CourseStatus._(this.kind, this.label, this.grade);

  /// Resolves the badge in a fixed priority order.
  ///
  /// An incomplete total weight always wins over missing scores: until the
  /// components add up to 100% the computed grade is meaningless, so the card
  /// shows `-` instead of a number the user might trust.
  ///
  /// Pass `totalComponents: 0` when the per-course component breakdown could
  /// not be loaded — the weight alone is still enough to flag an unfinished
  /// rubric, and anything else degrades to [CourseStatusKind.complete].
  factory CourseStatus.evaluate({
    required double totalWeight,
    required int filledComponents,
    required int totalComponents,
    required double totalScore,
  }) {
    if (totalWeight < 100) {
      return CourseStatus._(
        CourseStatusKind.missingWeight,
        'Bobot ${formatDouble(totalWeight)}%',
        '-',
      );
    }
    if (totalComponents > 0 && filledComponents < totalComponents) {
      return CourseStatus._(
        CourseStatusKind.missingScores,
        '$filledComponents/$totalComponents nilai diisi',
        getFinalGrade(totalScore),
      );
    }
    return CourseStatus._(
      CourseStatusKind.complete,
      'nilai lengkap',
      getFinalGrade(totalScore),
    );
  }

  final CourseStatusKind kind;

  /// Trailing half of the subtitle, e.g. `nilai lengkap` or `Bobot 30%`.
  final String label;

  /// Letter grade for the right edge of the card, `-` when not yet meaningful.
  final String grade;

  /// Whether the label needs the warning triangle in front of it.
  bool get hasWarning => kind == CourseStatusKind.missingWeight;

  /// Whether the grade is final rather than a running estimate.
  bool get isComplete => kind == CourseStatusKind.complete;
}
