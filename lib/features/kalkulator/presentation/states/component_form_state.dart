part of '_states.dart';

class ComponentFormState {
  /// [repo] is injectable only so tests can drive the edit-mode fetch with
  /// seeded nullable/empty scores; production passes nothing and gets the
  /// real implementation.
  ComponentFormState({ComponentRepository? repo}) {
    _repo = repo ?? ComponentRepositoryImpl(ComponentRemoteDataSourceImpl());
    _frequency.text = '1';
    getCachedRecommendation();
  }

  late ComponentRepository _repo;
  final formKey = GlobalKey<FormState>();
  var _formData = ComponentData()..score = <int, double?>{};
  final _nameController = TextEditingController();
  final _scoreControllers = <TextEditingController>[TextEditingController()];
  final _weightController = TextEditingController();
  final _frequency = TextEditingController();

  static const _defaultRecommendedScore = 85.0;

  String _previousFrequency = '1';
  double _recommendedScore = _defaultRecommendedScore;
  bool isLoading = false;
  bool justVisited = true;

  final _recommendation = <String>[];

  /// Get details information of passed component
  Future<void> retrieveDetailedComponent(QueryComponent q) async {
    final resp = await _repo.getDetailComponent(q);
    resp.fold((failure) {
      throw failure;
    }, (result) {
      final detail = result.data;
      final rawScores = (detail['scores'] as List?) ?? const [];
      _frequency.text = rawScores.length.toString();
      _scoreControllers.clear();
      _formData.score!.clear();
      for (var i = 0; i < rawScores.length; i++) {
        // The API sends whole numbers as int, so the map — typed
        // `Map<int, double?>` — needs the coercion or it throws at runtime.
        final score = (rawScores[i] as num?)?.toDouble();
        _scoreControllers.add(TextEditingController());
        scoreControllers.last.text = score == null ? '' : _formatScore(score);
        _formData.score![i + 1] = score;
      }
      if (_scoreControllers.isEmpty) {
        _scoreControllers.add(TextEditingController());
        _frequency.text = '1';
        _formData.score![1] = null;
      }
      _previousFrequency = _frequency.text;
      _recommendedScore = (detail['recommended_score'] as num?)?.toDouble() ??
          _defaultRecommendedScore;
      justVisited = true;
    });
    await getCachedRecommendation();
  }

  /// Submitting form data
  Future<void> submitForm(int calculatorId) async {
    isLoading = true;
    componentFormRM.notify();
    final result = <String, dynamic>{};

    final scores = scoresPayload();

    result['calculator_id'] = calculatorId;
    result['name'] = _formData.name;
    result['weight'] = _formData.weight;
    result['frequency'] = scores.length;
    result['scores'] = scores;

    final resp = await _repo.createComponent(result);
    isLoading = false;
    componentFormRM.notify();
    resp.fold(
      (failure) => throw failure,
      (_) {},
    );

    if (_formData.name != null && _formData.name!.isNotEmpty) {
      await addNewCachedRecommendation(_formData.name!);
    }
  }

  Future<void> submitEditForm(int id) async {
    isLoading = true;
    componentFormRM.notify();
    final result = <String, dynamic>{};

    final scores = scoresPayload();

    result['score_component_id'] = id;
    result['name'] = _formData.name;
    result['weight'] = _formData.weight;
    result['frequency'] = scores.length;
    result['scores'] = scores;

    final resp = await _repo.editComponent(result);
    isLoading = false;
    componentFormRM.notify();
    resp.fold(
      (failure) => throw failure,
      (_) {},
    );

    if (_formData.name != null && _formData.name!.isNotEmpty) {
      await addNewCachedRecommendation(_formData.name!);
    }
  }

  ComponentData get formData => _formData;
  double get recommendedScore => _recommendedScore;

  TextEditingController get nameController => _nameController;
  List<TextEditingController> get scoreControllers => _scoreControllers;
  TextEditingController get weightController => _weightController;
  TextEditingController get frequency => _frequency;
  List<String> get recommendation => _recommendation;

  set previousFrequency(String value) => _previousFrequency = value;

  void setName() {
    _formData.name = nameController.text;
  }

  /// How many occurrences are actually addressable right now.
  ///
  /// [_frequency] is the live controller behind the stepper's text field, so
  /// typing in it moves ahead of [_scoreControllers], which only resync on
  /// submit. Reading the raw text as a loop bound therefore overruns the list.
  int get effectiveLength {
    final parsed = int.tryParse(_frequency.text) ?? _scoreControllers.length;
    if (parsed < 0 || _scoreControllers.isEmpty) {
      return 0;
    }
    final available = _scoreControllers.length;
    return parsed < available ? parsed : available;
  }

  /// An occurrence left blank stays `null` — it is "not graded yet", which is
  /// not the same as scoring a zero.
  double? parseScore(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  /// The scores exactly as typed, nulls included, taken from the controllers
  /// so what is sent always matches what is on screen.
  List<double?> scoresPayload() => [
        for (var i = 0; i < effectiveLength; i++)
          parseScore(_scoreControllers[i].text),
      ];

  String _formatScore(double score) =>
      score == score.roundToDouble() ? score.toStringAsFixed(0) : '$score';

  void setScore(int index) {
    if (index < 1 || index > _scoreControllers.length) {
      return;
    }
    _formData.score![index] = parseScore(scoreControllers[index - 1].text);
  }

  /// True deletion of one occurrence — not clearing its value, removing it.
  ///
  /// The `x` on each row: unlike backspacing a score to blank (which leaves
  /// the row as "not graded yet"), this drops the row outright, shifts every
  /// later occurrence up by one index, and decrements frequency to match —
  /// so deleting "Nilai 2" out of 3 turns "Nilai 3" into "Nilai 2" without
  /// the user first clearing rows from the bottom. Can walk a component all
  /// the way down to zero occurrences; [effectiveLength] and [averageScore]
  /// already treat an empty controller list as "nothing to show" rather than
  /// a bound to guard against, so frequency 0 renders, it just renders empty.
  void deleteRow(int index) {
    if (index < 1 || index > _scoreControllers.length) {
      return;
    }

    _scoreControllers.removeAt(index - 1);

    final shifted = <int, double?>{};
    _formData.score?.forEach((key, value) {
      if (key < index) {
        shifted[key] = value;
      } else if (key > index) {
        shifted[key - 1] = value;
      }
    });
    _formData.score = shifted;

    _frequency.text = _scoreControllers.length.toString();
    _previousFrequency = _frequency.text;

    componentFormRM.notify();
  }

  void setWeight() {
    final normalizedValue = weightController.text.trim().replaceAll(',', '.');
    // The field validator blocks anything unparseable before this runs; the
    // fallback keeps the last good weight rather than throwing on a stray call.
    _formData.weight = double.tryParse(normalizedValue) ?? _formData.weight;
  }

  /// Cleaning form when success submitting form
  void cleanForm() {
    _formData = ComponentData();
    _formData.score = <int, double?>{};
    // Otherwise a fresh form inherits the recommendation of whatever
    // component was open last.
    _recommendedScore = _defaultRecommendedScore;

    _nameController.text = '';
    _weightController.text = '';

    setFrequency(1, false);
    for (final element in _scoreControllers) {
      element.clear();
    }

    justVisited = true;
  }

  void decreaseFrequency() {
    // Not `int.parse`: the stepper's text field can be sitting empty.
    final currentLength =
        int.tryParse(_frequency.text) ?? _scoreControllers.length;
    if (currentLength <= 1 || _scoreControllers.length <= 1) {
      return;
    }

    _formData.score!.remove(currentLength);

    _frequency.text = (currentLength - 1).toString();
    _scoreControllers.removeLast();

    _previousFrequency = _frequency.text;

    componentFormRM.notify();
  }

  void increaseFrequency() {
    final currentLength =
        int.tryParse(_frequency.text) ?? _scoreControllers.length;
    _frequency.text = (currentLength + 1).toString();
    _scoreControllers.add(TextEditingController());

    _formData.score![currentLength + 1] = null;

    _previousFrequency = _frequency.text;

    componentFormRM.notify();
  }

  void setFrequency(int value, bool isExceed) {
    if (isExceed) {
      _frequency.text = _previousFrequency;
    } else {
      _frequency.text = value.toString();

      if (_scoreControllers.length != value) {
        if (_scoreControllers.length > value) {
          _scoreControllers.removeRange(value, _scoreControllers.length);
          _formData.score!.removeWhere((key, _) => key > value);
        } else {
          _scoreControllers.addAll(
            List.generate(
              value - _scoreControllers.length,
              (_) => TextEditingController(),
            ),
          );
        }
      }

      for (var i = 1; i < value + 1; i++) {
        _formData.score!.putIfAbsent(i, () => null);
      }
    }

    _previousFrequency = _frequency.text;

    componentFormRM.notify();
  }

  /// Average across the occurrences that actually have a score.
  ///
  /// A blank occurrence is left out of both the sum and the divisor, so one
  /// quiz of 80 out of two scheduled averages 80, not 40. Null only when
  /// nothing at all is filled — which the UI renders as `Kosong`. Mirrors
  /// [ComponentBreakdown.average] so the sheet and the detail page agree.
  double? averageScore() {
    var sum = 0.0;
    var valid = 0;

    for (var i = 0; i < effectiveLength; i++) {
      final score = parseScore(_scoreControllers[i].text);
      if (score != null) {
        sum += score;
        valid++;
      }
    }

    // Deliberately not `sum != 0`: a genuine all-zero average is a real score,
    // not an empty component.
    return valid == 0 ? null : sum / valid;
  }

  final initRecommendation = [
    'Tugas Individu',
    'Tugas Kelompok',
    'UTS',
    'UAS',
    'Kuis',
    'Partisipasi',
    'Refleksi',
  ];

  Future<void> getCachedRecommendation() async {
    if (Pref.getString('cached_recommendation') == null) {
      await Pref.saveString(
        'cached_recommendation',
        initRecommendation.join(','),
      );
    } else {
      final cached = Pref.getString('cached_recommendation')!;
      _recommendation
        ..clear()
        ..addAll(cached.split(','));
    }
  }

  Future<void> addNewCachedRecommendation(String recommendation) async {
    if (!_recommendation.contains(recommendation.toLowerCase())) {
      _recommendation.insert(0, recommendation);

      final customRecommendations = _recommendation
          .where((item) => !initRecommendation.contains(item))
          .take(5)
          .toList();

      _recommendation
        ..clear()
        ..addAll(customRecommendations)
        ..addAll(initRecommendation);

      await Pref.saveString(
        'cached_recommendation',
        _recommendation.join(','),
      );
    }
  }

  /// Showcase only
  Future<void> fakeLoading() async {
    isLoading = true;
    componentFormRM.notify();
    await Future.delayed(
      const Duration(milliseconds: 1500),
    );
    isLoading = false;
    componentFormRM.notify();
  }
}

class ComponentData {
  String? name;
  Map<int, double?>? score;
  double? weight;
}
