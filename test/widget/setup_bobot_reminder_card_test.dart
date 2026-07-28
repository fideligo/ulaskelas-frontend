import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulaskelas/features/kalkulator/data/models/component_model.dart';
import 'package:ulaskelas/features/kalkulator/domain/entities/component_breakdown.dart';
import 'package:ulaskelas/features/kalkulator/presentation/states/_states.dart';
import 'package:ulaskelas/features/kalkulator/presentation/widgets/_widgets.dart';

import 'widget_test.dart';

ComponentBreakdown breakdown({
  required String name,
  required double weight,
  required List<double?> scores,
}) {
  return ComponentBreakdown(
    component: ComponentModel(id: 1, name: name, weight: weight),
    scores: scores,
  );
}

void main() {
  group('SetupBobotReminderCard', () {
    Future<void> pumpCard(WidgetTester tester, double totalWeight) async {
      await tester.pumpWidget(
        material(
          Scaffold(
            body: SetupBobotReminderCard(totalWeight: totalWeight),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the title and the reminder copy', (tester) async {
      await pumpCard(tester, 30);

      expect(find.text('Setup Bobot Komponen'), findsOneWidget);
      expect(
        find.text(
          'Tambah komponen sampai 100% untuk aktifkan Rekomendasi Ruby',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reports the accumulated weight, 25% + 5% = 30%',
        (tester) async {
      await pumpCard(tester, 25 + 5);

      expect(find.text('30%'), findsOneWidget);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.3, 1e-9));
    });

    testWidgets('renders fractional weights without trailing noise',
        (tester) async {
      await pumpCard(tester, 7.5);

      expect(find.text('7.5%'), findsOneWidget);
    });

    testWidgets('uses the exact specified fill, border and amber',
        (tester) async {
      await pumpCard(tester, 30);

      const background = Color(0xFFFEFCE8);
      const accent = Color(0xFFF0B100);

      final decoration = tester
          .widget<Container>(
            find
                .descendant(
                  of: find.byType(SetupBobotReminderCard),
                  matching: find.byType(Container),
                )
                .first,
          )
          .decoration! as BoxDecoration;

      expect(decoration.color, background);
      expect(decoration.border!.top.color, accent);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.valueColor!.value, accent);

      final percentage = tester.widget<Text>(find.text('30%'));
      expect(percentage.style!.color, accent);

      final footer = tester.widget<Text>(
        find.text(
          'Tambah komponen sampai 100% untuk aktifkan Rekomendasi Ruby',
        ),
      );
      expect(footer.style!.color, accent);
    });

    testWidgets('clamps the bar rather than overflowing past 100',
        (tester) async {
      await pumpCard(tester, 140);

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0);
      // The number itself is not clamped — the user needs to see the overshoot.
      expect(find.text('140%'), findsOneWidget);
    });
  });

  group('Ruby recommendation gating', () {
    test('is withheld entirely while the rubric is under 100%', () {
      final state = CalculatorComponentState();

      // No breakdowns yet, so the weights cannot add up.
      expect(state.hasFullWeight, isFalse);

      // Even a fully graded component reports nothing: a target computed
      // against a partial rubric would be misleading.
      expect(state.recommendationFor(score: 88), isNull);
      expect(state.recommendationFor(score: null), isNull);
    });
  });

  group('CardComponentExpansion under an incomplete rubric', () {
    testWidgets('blanks the Rek. Ruby column on the summary row',
        (tester) async {
      await tester.pumpWidget(
        material(
          Scaffold(
            body: CardComponentExpansion(
              breakdown: breakdown(
                name: 'UAS',
                weight: 25,
                scores: const [null],
              ),
              isExpanded: false,
              recommendation: null,
              rubyEnabled: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('UAS'), findsOneWidget);
      expect(find.text('0/1 terisi'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('blanks it on expanded occurrence rows too, even when graded',
        (tester) async {
      await tester.pumpWidget(
        material(
          Scaffold(
            body: CardComponentExpansion(
              breakdown: breakdown(
                name: 'Kuis',
                weight: 20,
                scores: const [80, null],
              ),
              isExpanded: true,
              recommendation: null,
              rubyEnabled: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1/2 terisi'), findsOneWidget);
      // One summary row plus two occurrence rows, none of them predicting.
      expect(find.text('-'), findsNWidgets(3));
    });
  });
}
