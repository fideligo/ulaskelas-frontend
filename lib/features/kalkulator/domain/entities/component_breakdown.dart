import 'package:ulaskelas/features/kalkulator/data/models/component_model.dart';

/// A grade component together with the individual scores behind it.
///
/// A component like `Kuis` can be graded several times; [scores] holds one
/// entry per occurrence, `null` where nothing has been entered yet.
class ComponentBreakdown {
  const ComponentBreakdown({
    required this.component,
    required this.scores,
  });

  /// Fallback for a component whose per-occurrence scores could not be
  /// loaded: treat the component's own score as a single occurrence.
  factory ComponentBreakdown.fromComponentOnly(ComponentModel component) {
    final score = component.score;
    return ComponentBreakdown(
      component: component,
      // The API marks an empty score as -1 rather than null.
      scores: [if (score == null || score == -1) null else score],
    );
  }

  final ComponentModel component;
  final List<double?> scores;

  int get id => component.id ?? -1;
  String get name => component.name ?? '-';
  double get weight => component.weight ?? 0;

  int get totalCount => scores.length;
  int get filledCount => scores.where((score) => score != null).length;

  bool get isFullyFilled => totalCount > 0 && filledCount == totalCount;
  bool get isEmpty => filledCount == 0;

  /// Average across the filled occurrences only.
  ///
  /// An empty occurrence is null, not zero — it is left out of both the sum
  /// and the divisor, so one 80 out of two quizzes averages 80, not 40.
  /// Null when nothing is filled, which the UI renders as `Kosong`.
  double? get average {
    if (filledCount == 0) {
      return null;
    }
    final total = scores.whereType<double>().reduce((a, b) => a + b);
    return total / filledCount;
  }

  /// What this component currently contributes to the final score.
  double get weightedScore => (average ?? 0) * weight / 100;

  /// Weight carried by a single occurrence — a 20% `Kuis` graded twice puts
  /// 10% on each.
  double get weightPerOccurrence =>
      totalCount == 0 ? weight : weight / totalCount;

  /// `Kuis 1`, `Kuis 2`, … or just the name when it is graded once.
  String occurrenceName(int index) =>
      totalCount > 1 ? '$name ${index + 1}' : name;
}
