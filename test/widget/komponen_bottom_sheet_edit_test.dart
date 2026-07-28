import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulaskelas/core/_core.dart';
import 'package:ulaskelas/core/error/_error.dart';
import 'package:ulaskelas/core/extension/_extension.dart';
import 'package:ulaskelas/features/kalkulator/data/models/component_model.dart';
import 'package:ulaskelas/features/kalkulator/domain/entities/query_component.dart';
import 'package:ulaskelas/features/kalkulator/domain/repositories/_repositories.dart';
import 'package:ulaskelas/features/kalkulator/presentation/states/_states.dart'
    show ComponentFormState;
import 'package:ulaskelas/features/kalkulator/presentation/widgets/_widgets.dart';
import 'package:ulaskelas/services/_services.dart';

import 'widget_test.dart';

/// Feeds the edit-mode detail fetch from a mutable [scores] list so each test
/// can seed a different set of occurrences before opening the sheet, without
/// ever touching the network — the exact reason edit mode had gone untested.
class _FakeDetailRepository implements ComponentRepository {
  List<num?> scores = <num?>[];

  @override
  Future<Decide<Failure, Parsed<Map<String, dynamic>>>> getDetailComponent(
    QueryComponent q,
  ) async {
    final detail = <String, dynamic>{
      'frequency': scores.length,
      'scores': scores,
      'recommended_score': 85,
    };
    return Right<Failure, Parsed<Map<String, dynamic>>>(
      Parsed<Map<String, dynamic>>.fromJson(<String, dynamic>{}, 200, detail),
    );
  }

  @override
  Future<Decide<Failure, Parsed<Map<String, dynamic>>>> getAllComponent(
    QueryComponent q,
  ) =>
      throw UnimplementedError();

  @override
  Future<Decide<Failure, Parsed<Map<String, dynamic>>>> getComponentSummary(
    int calculatorId,
  ) =>
      throw UnimplementedError();

  @override
  Future<Decide<Failure, Parsed<ComponentModel>>> createComponent(
    Map<String, dynamic> model,
  ) =>
      throw UnimplementedError();

  @override
  Future<Decide<Failure, Parsed<ComponentModel>>> editComponent(
    Map<String, dynamic> model,
  ) =>
      throw UnimplementedError();

  @override
  Future<Decide<Failure, Parsed<void>>> deleteComponent(QueryComponent q) =>
      throw UnimplementedError();
}

/// The sheet's own delete red, shared by the row X and "Hapus Komponen".
const _deleteRed = Color(0xFFFB2C36);

final _fakeRepo = _FakeDetailRepository();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Pref.init();
    // Rebuild the form state around the fake repo, so opening the sheet in
    // edit mode resolves its fetch from seeded data instead of the network.
    componentFormRM.injectMock(() => ComponentFormState(repo: _fakeRepo));
  });

  Future<void> openEdit(
    WidgetTester tester, {
    required List<num?> scores,
  }) async {
    _fakeRepo.scores = scores;
    await tester.pumpWidget(
      material(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => unawaited(
                  KomponenBottomSheet.showEdit(
                    context,
                    id: 1,
                    componentName: 'UTS',
                    componentWeight: 20,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the red "Hapus Komponen" action, unlike add mode', (
    tester,
  ) async {
    await openEdit(tester, scores: <num?>[80, 90]);

    expect(find.text('Edit Komponen'), findsOneWidget);
    expect(find.text('Hapus Komponen'), findsOneWidget);
    final label = tester.widget<Text>(find.text('Hapus Komponen'));
    expect(label.style?.color, _deleteRed);
  });

  testWidgets('frequency > 1 opens collapsed to just the Rata Rata row', (
    tester,
  ) async {
    await openEdit(tester, scores: <num?>[80, 90]);

    // The summary stays visible; the per-frequency rows are hidden and the
    // arrow points down, inviting the tap that reveals them.
    expect(find.text('Rata Rata'), findsOneWidget);
    expect(find.text('Nilai 1'), findsNothing);
    expect(find.text('Nilai 2'), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);

    await tester.tap(find.text('Nilai tiap komponen'));
    await tester.pumpAndSettle();

    // Tapping the arrow reveals the individual, editable frequency scores.
    expect(find.text('Nilai 1'), findsOneWidget);
    expect(find.text('Nilai 2'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
  });

  testWidgets('a single occurrence renders its row directly, no arrow', (
    tester,
  ) async {
    await openEdit(tester, scores: <num?>[75]);

    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    expect(find.text('Nilai 1'), findsOneWidget);
  });

  testWidgets('removing a row via its X drops that occurrence', (
    tester,
  ) async {
    await openEdit(tester, scores: <num?>[80, 90]);
    await tester.tap(find.text('Nilai tiap komponen'));
    await tester.pumpAndSettle();

    expect(find.text('Nilai 2'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '90'), findsOneWidget);

    // The header close is 22px; the per-row X is 16px, so size pins the
    // finder to the two row icons. The last one is the bottom row's ("90").
    // The sheet scrolls, so bring it into view before a tap can land on it.
    final rowDelete = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.close && w.size == 16,
    );
    expect(rowDelete, findsNWidgets(2));

    await tester.ensureVisible(rowDelete.last);
    await tester.pumpAndSettle();
    await tester.tap(rowDelete.last);
    await tester.pumpAndSettle();

    // The second occurrence (90) is physically gone; only "Nilai 1" (80)
    // remains, and nothing threw casting the scores along the way.
    expect(tester.takeException(), isNull);
    expect(find.text('Nilai 2'), findsNothing);
    expect(find.text('Nilai 1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '90'), findsNothing);
    expect(find.widgetWithText(TextFormField, '80'), findsOneWidget);
  });
}
