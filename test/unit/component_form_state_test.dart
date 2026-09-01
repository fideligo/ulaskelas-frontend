import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulaskelas/core/error/_error.dart';
import 'package:ulaskelas/core/extension/_extension.dart';
import 'package:ulaskelas/features/kalkulator/data/models/component_model.dart';
import 'package:ulaskelas/features/kalkulator/domain/entities/query_component.dart';
import 'package:ulaskelas/features/kalkulator/domain/repositories/_repositories.dart';
import 'package:ulaskelas/features/kalkulator/presentation/states/_states.dart';
import 'package:ulaskelas/services/_services.dart';

/// A [ComponentRepository] that answers only the edit-mode detail fetch, with
/// a seeded score list — every other call is a test bug, so it throws.
class _SeededComponentRepository implements ComponentRepository {
  _SeededComponentRepository({required this.scores});

  final List<num?> scores;

  @override
  Future<Decide<Failure, Parsed<Map<String, dynamic>>>> getDetailComponent(
    QueryComponent q,
  ) async {
    // Mirrors ComponentRemoteDataSourceImpl.getDetailComponent's shape, and
    // deliberately keeps whole numbers as `int` the way the real API sends
    // them — that is exactly the value the `as num?` coercion has to survive.
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

/// Builds a form state whose detail fetch returns [scores], then runs that
/// fetch so the controllers end up exactly as opening the edit sheet leaves
/// them.
Future<ComponentFormState> seededForm(List<num?> scores) async {
  final state = ComponentFormState(
    repo: _SeededComponentRepository(scores: scores),
  );
  await state.retrieveDetailedComponent(
    QueryComponent(scoreComponentId: 1),
  );
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The constructor reads the cached recommendation from SharedPreferences,
    // so the store has to exist before any state is built.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Pref.init();
  });

  group('retrieveDetailedComponent (edit-mode fetch)', () {
    test('coerces integer API scores to double without a cast error',
        () async {
      final state = await seededForm(<num?>[80, 90]);

      expect(state.frequency.text, '2');
      expect(state.scoreControllers.length, 2);
      expect(state.scoreControllers[0].text, '80');
      expect(state.scoreControllers[1].text, '90');
      expect(state.averageScore(), 85);
    });

    test('keeps an empty occurrence blank rather than scoring it a zero',
        () async {
      final state = await seededForm(<num?>[80, null]);

      expect(state.frequency.text, '2');
      expect(state.scoreControllers[1].text, '');
      // One 80 out of two scheduled averages 80, not 40.
      expect(state.averageScore(), 80);
    });

    test('reports a null average when nothing at all is filled', () async {
      final state = await seededForm(<num?>[null, null]);

      expect(state.effectiveLength, 2);
      expect(state.averageScore(), isNull);
    });

    test('falls back to a single blank occurrence for an empty score list',
        () async {
      final state = await seededForm(<num?>[]);

      expect(state.frequency.text, '1');
      expect(state.scoreControllers.length, 1);
      expect(state.averageScore(), isNull);
    });
  });

  group('deleteRow (the X on a score row)', () {
    test('removes one occurrence, shifts the rest up and drops frequency',
        () async {
      final state = await seededForm(<num?>[80, null, 90]);

      // Delete the empty middle occurrence.
      state.deleteRow(2);

      expect(state.effectiveLength, 2);
      expect(state.frequency.text, '2');
      expect(state.scoreControllers.length, 2);
      expect(state.scoreControllers[0].text, '80');
      // "Nilai 3" has slid up into the "Nilai 2" slot.
      expect(state.scoreControllers[1].text, '90');
      expect(state.averageScore(), 85);
      expect(state.formData.score, <int, double?>{1: 80.0, 2: 90.0});
    });

    test('recomputes the average once the graded row is removed', () async {
      final state = await seededForm(<num?>[80, 90]);

      state.deleteRow(1);

      expect(state.frequency.text, '1');
      expect(state.effectiveLength, 1);
      expect(state.scoreControllers.single.text, '90');
      expect(state.averageScore(), 90);
    });

    test('walks down to zero occurrences with nothing left to average',
        () async {
      final state = await seededForm(<num?>[80]);

      state.deleteRow(1);

      expect(state.scoreControllers, isEmpty);
      expect(state.effectiveLength, 0);
      expect(state.averageScore(), isNull);
    });
  });
}
