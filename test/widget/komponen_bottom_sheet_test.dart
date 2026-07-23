import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ristek_material_component/ristek_material_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulaskelas/core/_core.dart';
import 'package:ulaskelas/features/kalkulator/presentation/widgets/_widgets.dart';
import 'package:ulaskelas/services/_services.dart';

import 'widget_test.dart';

/// Add mode is the only branch that opens without a network call, so it is the
/// one that can be pumped honestly. Edit mode hits `retrieveDetailedComponent`
/// on init and is left to manual testing.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Pref.init();
    componentFormRM.state.cleanForm();
  });

  Future<void> openAddSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      material(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    KomponenBottomSheet.showAdd(context, calculatorId: 1),
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
}
