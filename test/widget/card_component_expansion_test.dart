import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulaskelas/features/kalkulator/data/models/component_model.dart';
import 'package:ulaskelas/features/kalkulator/domain/entities/component_breakdown.dart';
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
  Future<void> pumpExpanded(
    WidgetTester tester,
    ComponentBreakdown data, {
    double? recommendation,
    double? occurrenceRecommendation,
    bool rubyEnabled = true,
  }) async {
    await tester.pumpWidget(
      material(
        Scaffold(
          body: CardComponentExpansion(
            breakdown: data,
            isExpanded: true,
            recommendation: recommendation,
            occurrenceRecommendation: occurrenceRecommendation,
            rubyEnabled: rubyEnabled,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('occurrence numbering', () {
    testWidgets('each row is suffixed with its 1-based index', (
      tester,
    ) async {
      await pumpExpanded(
        tester,
        breakdown(name: 'Kuis', weight: 20, scores: const [80, null]),
        occurrenceRecommendation: 80,
      );

      // The summary row above still shows the bare "Kuis" — only the
      // occurrence rows underneath must carry the index.
      expect(find.text('Kuis 1'), findsOneWidget);
      expect(find.text('Kuis 2'), findsOneWidget);
    });

    testWidgets('a single occurrence is still numbered "1"', (tester) async {
      await pumpExpanded(
        tester,
        breakdown(name: 'UTS', weight: 25, scores: const [null]),
        occurrenceRecommendation: 85,
      );

      expect(find.text('UTS 1'), findsOneWidget);
    });
  });

  group('grey pill styling', () {
    testWidgets('every occurrence sits in its own #F4F4F5 rounded container', (
      tester,
    ) async {
      await pumpExpanded(
        tester,
        breakdown(name: 'Kuis', weight: 20, scores: const [80, null]),
        occurrenceRecommendation: 80,
      );

      final pills = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == const Color(0xFFF4F4F5));

      expect(pills.length, 2);
      for (final pill in pills) {
        expect((pill.borderRadius! as BorderRadius).topLeft.x, 12);
      }
    });
  });

  group('column cleanup', () {
    testWidgets('the expanded pill carries no per-occurrence weight text', (
      tester,
    ) async {
      await pumpExpanded(
        tester,
        breakdown(name: 'Kuis', weight: 20, scores: const [80, null]),
        occurrenceRecommendation: 80,
      );

      // The summary row above still states the component's own weight
      // ("20%") once — only the pills themselves must not repeat it.
      final pillFinder = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                const Color(0xFFF4F4F5),
      );
      expect(pillFinder, findsNWidgets(2));
      expect(
        find.descendant(of: pillFinder, matching: find.textContaining('%')),
        findsNothing,
      );
    });

    testWidgets('a filled score renders dark, an empty one renders "Kosong"', (
      tester,
    ) async {
      await pumpExpanded(
        tester,
        breakdown(name: 'Kuis', weight: 20, scores: const [80, null]),
        occurrenceRecommendation: 80,
      );

      expect(find.text('80.00'), findsWidgets);
      expect(find.text('Kosong'), findsOneWidget);

      final placeholder = tester.widget<Text>(find.text('Kosong'));
      expect(placeholder.style!.color, const Color(0xFF9CA3AF));
    });

    testWidgets(
      "Ruby's prediction is bold purple only for the empty occurrence",
      (tester) async {
        await pumpExpanded(
          tester,
          breakdown(name: 'Kuis', weight: 20, scores: const [80, null]),
          occurrenceRecommendation: 80,
        );

        // Row 1 is graded (80.00 shown twice: its own score and, since
        // filled, the same number in the Ruby column) — row 2 is empty, so
        // its Ruby column is the only bold-purple "80.00" on screen.
        final purpleBold = tester
            .widgetList<Text>(find.text('80.00'))
            .where(
              (t) =>
                  t.style!.color == const Color(0xFF5038BC) &&
                  t.style!.fontWeight == FontWeight.w700,
            );

        expect(purpleBold.length, 1);
      },
    );
  });

  group('edit komponen placement', () {
    testWidgets('sits below the occurrence pills, left-aligned', (
      tester,
    ) async {
      var edited = false;

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
              recommendation: 80,
              occurrenceRecommendation: 80,
              onEdit: () => edited = true,
            ),
          ),
        ),
      );
      await tester.pump();

      final editY = tester.getTopLeft(find.text('Edit Komponen')).dy;
      final lastPillY = tester.getBottomLeft(find.text('Kuis 2')).dy;
      expect(editY, greaterThan(lastPillY));

      await tester.tap(find.text('Edit Komponen'));
      expect(edited, isTrue);
    });
  });
}
