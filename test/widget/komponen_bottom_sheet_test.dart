import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ristek_material_component/ristek_material_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulaskelas/core/_core.dart';
import 'package:ulaskelas/features/kalkulator/presentation/widgets/_widgets.dart';
import 'package:ulaskelas/services/_services.dart';

import 'widget_test.dart';

/// Add mode is the only branch that opens without a network call, so it is the
/// one pumped honestly here. Edit mode hits `retrieveDetailedComponent` on
/// init, so its seeded-fetch coverage (collapsed default, row deletion) lives
/// in `komponen_bottom_sheet_edit_test.dart`, which mocks the repository.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Pref.init();
    componentFormRM.state.cleanForm();
  });

  /// Captures whatever the sheet resolves to, so tests can assert on the
  /// contract the detail page depends on.
  late KomponenSheetResult? result;
  late bool resolved;

  Future<void> openSheet(WidgetTester tester, {bool isEdit = false}) async {
    resolved = false;
    result = null;

    await tester.pumpWidget(
      material(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final value = isEdit
                      ? await KomponenBottomSheet.showEdit(
                          context,
                          id: 1,
                          componentName: 'Kuis',
                          componentWeight: 7.5,
                        )
                      : await KomponenBottomSheet.showAdd(
                          context,
                          calculatorId: 1,
                        );
                  result = value;
                  resolved = true;
                },
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

  Future<void> openAddSheet(WidgetTester tester) => openSheet(tester);

  testWidgets('add mode titles itself and its primary action correctly',
      (tester) async {
    await openAddSheet(tester);

    // Title and button share the string, so both must be present.
    expect(find.text('Tambah Komponen'), findsNWidgets(2));
    expect(find.text('Edit Komponen'), findsNothing);
    expect(find.text('Simpan Nilai'), findsNothing);
  });

  testWidgets('add mode omits the delete action entirely', (tester) async {
    await openAddSheet(tester);

    expect(find.text('Hapus Komponen'), findsNothing);
  });

  testWidgets('add mode starts with clean, empty fields', (tester) async {
    await openAddSheet(tester);

    expect(componentFormRM.state.nameController.text, '');
    expect(componentFormRM.state.weightController.text, '');
    expect(componentFormRM.state.frequency.text, '1');
    expect(componentFormRM.state.effectiveLength, 1);
    expect(componentFormRM.state.averageScore(), isNull);
  });

  testWidgets('the scores section renders rather than stalling on idle',
      (tester) async {
    await openAddSheet(tester);

    // The section is behind `OnBuilder.all`, which shows a spinner while the
    // state is idle — add mode runs nothing async, so this asserts it still
    // reaches the data branch.
    expect(find.text('Nilai tiap komponen'), findsOneWidget);
    expect(find.text('Boleh kosong, Ruby hitung targetnya'), findsOneWidget);
    expect(find.text('Nilai 1'), findsOneWidget);
    expect(find.text('Rata Rata'), findsOneWidget);
    expect(find.byType(CircleLoading), findsNothing);
  });

  testWidgets('the sheet paints pure #FFFFFF, not a tinted surface',
      (tester) async {
    await openAddSheet(tester);

    final decorated = tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    );
    final backgrounds = decorated
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == const Color(0xFFFFFFFF));

    expect(backgrounds, isNotEmpty);
  });

  testWidgets('the primary button uses the exact brand fill', (tester) async {
    await openAddSheet(tester);

    final fills = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == const Color(0xFF5038BC));

    expect(fills, isNotEmpty);
  });

  testWidgets('an empty score keeps the average null, not zero',
      (tester) async {
    await openAddSheet(tester);

    componentFormRM.state
      ..increaseFrequency()
      ..scoreControllers[0].text = '80';

    expect(componentFormRM.state.averageScore(), 80);

    // The blank second occurrence must not drag the average to 40.
    expect(componentFormRM.state.scoresPayload(), <double?>[80, null]);
  });

  testWidgets('an all-zero component averages zero, not null', (tester) async {
    await openAddSheet(tester);

    componentFormRM.state
      ..increaseFrequency()
      ..scoreControllers[0].text = '0'
      ..scoreControllers[1].text = '0';

    expect(componentFormRM.state.averageScore(), 0);
  });

  group('navigation safety', () {
    testWidgets('dismissing via the close button resolves to null',
        (tester) async {
      await openAddSheet(tester);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, isNull);
      expect(find.text('Tambah Komponen'), findsNothing);
    });

    testWidgets(
        'confirming delete closes the sheet and reports deleted, '
        'without popping a toast route', (tester) async {
      await openSheet(tester, isEdit: true);
      expect(find.text('Edit Komponen'), findsOneWidget);

      await tester.tap(find.text('Hapus Komponen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      // The crash was an AssertionError raised while popping. If the sheet
      // popped a Flushbar route instead of itself, this is where it surfaces.
      expect(tester.takeException(), isNull);
      expect(resolved, isTrue);
      expect(result?.action, KomponenSheetAction.deleted);
      // The name has to survive the pop — the caller quotes it in the banner
      // after the shared form state has already been cleared.
      expect(result?.name, 'Kuis');
      expect(result?.message, 'Komponen Kuis berhasil dihapus!');
      expect(find.text('Edit Komponen'), findsNothing);
    });

    testWidgets('cancelling delete leaves the sheet open and unresolved',
        (tester) async {
      await openSheet(tester, isEdit: true);

      await tester.tap(find.text('Hapus Komponen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(resolved, isFalse);
      expect(find.text('Edit Komponen'), findsOneWidget);
    });

    testWidgets('a validation failure reports inline and pushes no route',
        (tester) async {
      await openAddSheet(tester);

      // Name and weight are both empty, so validation must fail.
      await tester.tap(find.text('Tambah Komponen').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Pastikan semua field sudah terisi dengan benar!'),
        findsOneWidget,
      );
      // Still open, still unresolved: nothing was popped.
      expect(resolved, isFalse);
      expect(find.text('Tambah Komponen'), findsNWidgets(2));
    });
  });

  group('row deletion via X', () {
    testWidgets(
        'deleting a middle row shifts later occurrences up and '
        'decrements frequency', (tester) async {
      await openAddSheet(tester);

      componentFormRM.state
        ..increaseFrequency() // 1 -> 2
        ..increaseFrequency(); // 2 -> 3
      await tester.pump();

      componentFormRM.state.scoreControllers[0].text = '10';
      componentFormRM.state.scoreControllers[1].text = '20';
      componentFormRM.state.scoreControllers[2].text = '30';

      // Delete row 2 (the "20").
      componentFormRM.state.deleteRow(2);
      await tester.pump();

      expect(componentFormRM.state.frequency.text, '2');
      expect(componentFormRM.state.scoreControllers.length, 2);
      expect(componentFormRM.state.scoreControllers[0].text, '10');
      // Row 3 ("30") shifted up into row 2's slot.
      expect(componentFormRM.state.scoreControllers[1].text, '30');
      expect(componentFormRM.state.effectiveLength, 2);
      expect(componentFormRM.state.scoresPayload(), <double?>[10, 30]);
    });

    testWidgets('tapping the last row X removes it and steps frequency down',
        (tester) async {
      await openAddSheet(tester);

      componentFormRM.state
        ..increaseFrequency()
        ..increaseFrequency();
      await tester.pump();

      expect(find.text('Nilai 3'), findsOneWidget);

      // The last close icon in the tree is unambiguously row 3's — the
      // header's sits structurally above the whole scores section, and this
      // is the bottommost row within it. The sheet's own scroll view can
      // leave it below the test viewport, so it needs scrolling into view
      // before a tap actually lands on it rather than on empty space.
      final rowClose = find.byIcon(Icons.close).last;
      await tester.ensureVisible(rowClose);
      await tester.pumpAndSettle();
      await tester.tap(rowClose);
      await tester.pump();

      expect(componentFormRM.state.frequency.text, '2');
      expect(find.text('Nilai 3'), findsNothing);
    });

    testWidgets(
        'deleting the only row at frequency 1 drops it to 0 without '
        'crashing', (tester) async {
      await openAddSheet(tester);
      expect(componentFormRM.state.frequency.text, '1');

      componentFormRM.state.deleteRow(1);
      await tester.pump();

      expect(componentFormRM.state.frequency.text, '0');
      expect(componentFormRM.state.scoreControllers, isEmpty);
      expect(componentFormRM.state.effectiveLength, 0);
      expect(componentFormRM.state.averageScore(), isNull);
      expect(componentFormRM.state.scoresPayload(), isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('accordion arrow gating', () {
    testWidgets('is hidden while frequency is 1, row renders directly',
        (tester) async {
      await openAddSheet(tester);

      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(find.text('Nilai 1'), findsOneWidget);
    });

    testWidgets('appears once frequency exceeds 1 and can collapse the rows',
        (tester) async {
      await openAddSheet(tester);

      componentFormRM.state.increaseFrequency();
      await tester.pump();

      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
      expect(find.text('Nilai 1'), findsOneWidget);
      expect(find.text('Nilai 2'), findsOneWidget);

      await tester.tap(find.text('Nilai tiap komponen'));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.text('Nilai 1'), findsNothing);
      expect(find.text('Nilai 2'), findsNothing);
      // Collapsed or not, the average stays on screen.
      expect(find.text('Rata Rata'), findsOneWidget);
    });

    testWidgets('reappears and re-hides as rows are added and deleted back',
        (tester) async {
      await openAddSheet(tester);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);

      componentFormRM.state.increaseFrequency();
      await tester.pump();
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);

      componentFormRM.state.deleteRow(2);
      await tester.pump();
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });
  });

  group('component name dropdown', () {
    testWidgets('is present with the standard recommendation seed',
        (tester) async {
      await openAddSheet(tester);

      expect(find.byType(DropDownField), findsOneWidget);
      expect(
        componentFormRM.state.initRecommendation,
        containsAll(<String>['UTS', 'UAS', 'Kuis', 'Tugas Kelompok']),
      );
    });
  });

  group('nullable saving', () {
    testWidgets(
        'frequency greater than filled scores still validates, '
        'submitting the blanks as nulls', (tester) async {
      await openAddSheet(tester);

      componentFormRM.state
        ..nameController.text = 'Kuis'
        ..weightController.text = '20'
        ..increaseFrequency() // 1 -> 2
        ..increaseFrequency() // 2 -> 3
        ..scoreControllers[0].text = '90';
      await tester.pump();

      // Two of the three rows are still blank; validation must not care.
      expect(componentFormRM.state.formKey.currentState!.validate(), isTrue);
      expect(
        componentFormRM.state.scoresPayload(),
        <double?>[90, null, null],
      );
    });
  });

  group('banner copy', () {
    test('an edited component reports the update wording', () {
      const result = KomponenSheetResult(
        action: KomponenSheetAction.saved,
        name: 'Kuis',
      );

      expect(result.message, 'Nilai Kuis tersimpan! Rekomendasi diupdate');
    });

    test('a new component reports the add wording', () {
      const result = KomponenSheetResult(
        action: KomponenSheetAction.added,
        name: 'Kuis',
      );

      expect(result.message, 'Komponen Kuis tersimpan! Rekomendasi diupdate');
    });

    test('a deleted component reports the delete wording', () {
      const result = KomponenSheetResult(
        action: KomponenSheetAction.deleted,
        name: 'Kuis',
      );

      expect(result.message, 'Komponen Kuis berhasil dihapus!');
    });
  });

  group('banner widget', () {
    testWidgets('renders the message with the success check icon',
        (tester) async {
      await tester.pumpWidget(
        material(
          const Scaffold(
            body: ActionSuccessBanner(
              message: 'Nilai Kuis tersimpan! Rekomendasi diupdate',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Nilai Kuis tersimpan! Rekomendasi diupdate'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
