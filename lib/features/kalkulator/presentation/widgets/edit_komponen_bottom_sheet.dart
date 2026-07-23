part of '_widgets.dart';

/// Editing a component as a sheet over the detail page instead of a push.
///
/// Replaces `EditComponentPage`. Because the detail page stays mounted
/// underneath, saving here just pops — the caller refetches — rather than
/// rebuilding the route with a locally guessed total the way the page did.
class EditKomponenBottomSheet extends StatefulWidget {
  const EditKomponenBottomSheet({
    required this.id,
    required this.componentName,
    required this.componentWeight,
    super.key,
  });

  final int id;
  final String componentName;
  final double componentWeight;

  /// Resolves to `true` when the component was saved or deleted, so the caller
  /// knows whether it has to refetch.
  static Future<bool?> show(
    BuildContext context, {
    required int id,
    required String componentName,
    required double componentWeight,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      // Required for the sheet to grow past half height and to sit above the
      // keyboard once a field takes focus.
      isScrollControlled: true,
      backgroundColor: BaseColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditKomponenBottomSheet(
        id: id,
        componentName: componentName,
        componentWeight: componentWeight,
      ),
    );
  }

  @override
  State<EditKomponenBottomSheet> createState() =>
      _EditKomponenBottomSheetState();
}

class _EditKomponenBottomSheetState extends State<EditKomponenBottomSheet> {
  bool _scoresExpanded = true;

  @override
  void initState() {
    super.initState();
    componentFormRM.setState((s) => s.cleanForm());
    componentFormRM.state.nameController.text = widget.componentName;
    componentFormRM.state.weightController.text =
        _formatWeight(widget.componentWeight);
    componentFormRM.setState(
      (s) => s.retrieveDetailedComponent(
        QueryComponent(scoreComponentId: widget.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Padding(
      // Lifts the whole sheet by exactly the keyboard height so no field ends
      // up underneath it.
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1, thickness: 1, color: BaseColors.gray5),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Form(
                  key: componentFormRM.state.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(),
                      const HeightSpace(18),
                      _buildWeightField(),
                      const HeightSpace(18),
                      _buildFrequencyRow(),
                      const HeightSpace(10),
                      _buildScoresSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: BaseColors.gray3,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Edit Komponen', style: FontTheme.poppins16w700black()),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            color: BaseColors.neutral100,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  /// `Nama Komponen *` — the asterisk is red, the label is not.
  Widget _buildRequiredLabel(String label) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: FontTheme.poppins12w400black().copyWith(fontSize: 13),
        children: [
          TextSpan(
            text: '*',
            style: FontTheme.poppins12w600black().copyWith(
              fontSize: 13,
              color: BaseColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('Nama Komponen'),
        const HeightSpace(8),
        DropDownField(
          controller: componentFormRM.state.nameController,
          onValidate: () => componentFormRM.setState((s) => s.setName()),
          value: '',
          items: componentFormRM.state.recommendation,
          setter: (dynamic newValue) {
            componentFormRM.state.nameController.text = newValue;
          },
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('Bobot Nilai (%)'),
        const HeightSpace(8),
        TextFormField(
          controller: componentFormRM.state.weightController,
          minLines: 1,
          style: FontTheme.poppins12w400black(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp('[0-9]+[,.]{0,1}[0-9]*')),
          ],
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'Contoh: 7,5',
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 16, top: 14),
              child: Text(
                '%',
                style: FontTheme.poppins14w700black(),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(),
          ),
          onChanged: (value) {
            if (value.trim().isEmpty) {
              componentFormRM.state.weightController.clear();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required.';
            }
            if (double.tryParse(value.replaceAll(',', '.')) == null) {
              return 'Please enter a valid number.';
            }
            componentFormRM.setState((s) => s.setWeight());
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyRow() {
    return OnReactive(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildRequiredLabel('Frekuensi'),
          FrequencyController(
            onIncrease: () => componentFormRM.state.increaseFrequency(),
            onDecrease: () => componentFormRM.state.decreaseFrequency(),
            onChangingValue: (value, isExceed) =>
                componentFormRM.state.setFrequency(value, isExceed),
            frequencyController: componentFormRM.state.frequency,
          ),
        ],
      ),
    );
  }

  Widget _buildScoresSection() {
    return OnBuilder<ComponentFormState>.all(
      listenTo: componentFormRM,
      onIdle: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircleLoading(),
      ),
      onWaiting: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircleLoading(),
      ),
      onError: (error, refresh) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Gagal memuat nilai komponen.',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.error,
          ),
        ),
      ),
      onData: (_) {
        final data = componentFormRM.state;
        final length = data.effectiveLength;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _scoresExpanded = !_scoresExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nilai tiap komponen',
                      style: FontTheme.poppins14w400black().copyWith(
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      _scoresExpanded
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: BaseColors.neutral100,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'Boleh kosong, Ruby hitung targetnya',
              style: FontTheme.poppins12w400black().copyWith(
                fontSize: 11,
                color: BaseColors.gray2,
              ),
            ),
            if (_scoresExpanded) ...[
              const HeightSpace(4),
              for (var i = 0; i < length; i++) _buildScoreRow(data, i),
              _buildAverageRow(data),
            ],
            const HeightSpace(16),
          ],
        );
      },
    );
  }

  /// `Nilai 1` — the typed score on the left, Ruby's number for that
  /// occurrence on the right.
  Widget _buildScoreRow(ComponentFormState data, int index) {
    final controller = data.scoreControllers[index];
    final entered = data.parseScore(controller.text);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nilai ${index + 1}',
                style: FontTheme.poppins14w400black().copyWith(fontSize: 13),
              ),
              Row(
                children: [
                  SizedBox(
                    height: 38,
                    width: 96,
                    child: TextFormField(
                      controller: controller,
                      style: FontTheme.poppins12w400black(),
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp('[0-9]+[,.]{0,1}[0-9]*'),
                        ),
                      ],
                      onChanged: (value) {
                        componentFormRM.setState(
                          (s) => s
                            ..justVisited = false
                            ..setScore(index + 1),
                        );
                      },
                      validator: (value) {
                        final score = data.parseScore(value ?? '');
                        if (score != null && score > 200) {
                          return '';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        // The row is a fixed height, so an error string would
                        // overflow it. The red border plus the `???` in the
                        // target pill carry the message instead.
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                        hintText: 'Kosong',
                        hintStyle: FontTheme.poppins12w400black().copyWith(
                          color: BaseColors.gray3,
                        ),
                        // The whole point of the nullable flow: getting back
                        // to empty has to be one tap, not a long backspace.
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              componentFormRM.state.clearScore(index + 1),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: BaseColors.error,
                          ),
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const WidthSpace(8),
                  _buildTargetPill(data, entered),
                ],
              ),
            ],
          ),
          const HeightSpace(6),
          const Divider(
            height: 1,
            thickness: 0.7,
            color: BaseColors.gray4,
          ),
        ],
      ),
    );
  }

  /// A graded occurrence shows what it scored; an empty one shows what Ruby
  /// says it still needs.
  Widget _buildTargetPill(ComponentFormState data, double? entered) {
    final value = entered ?? data.recommendedScore;
    final isOverMax = entered != null && entered > 200;

    return Container(
      height: 38,
      width: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverMax ? BaseColors.danger : BaseColors.purpleHearth,
        ),
      ),
      child: Text(
        isOverMax ? '???' : _formatNumber(value),
        style: FontTheme.poppins12w500black().copyWith(
          color: isOverMax ? BaseColors.danger : BaseColors.purpleHearth,
        ),
      ),
    );
  }

  Widget _buildAverageRow(ComponentFormState data) {
    final average = data.averageScore();
    final isOverMax = average != null && average > 200;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Rata Rata',
            style: FontTheme.poppins14w700black().copyWith(fontSize: 13),
          ),
          Text(
            // Null means nothing is graded yet, not a zero average.
            average == null
                ? '-'
                : isOverMax
                    ? '???'
                    : _formatNumber(average),
            style: FontTheme.poppins14w700black().copyWith(
              fontSize: 13,
              color: isOverMax ? BaseColors.error : BaseColors.neutral100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _onDelete,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Hapus Komponen',
                style: FontTheme.poppins14w500black().copyWith(
                  color: BaseColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const HeightSpace(8),
          OnReactive(
            () => SizedBox(
              width: double.infinity,
              child: AutoLayoutButton(
                text: 'Simpan Nilai',
                isLoading: componentFormRM.state.isLoading,
                onTap: _onSave,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (componentFormRM.state.isLoading) {
      return;
    }
    componentFormRM.state.justVisited = false;

    if (!componentFormRM.state.formKey.currentState!.validate()) {
      WarningMessenger('Pastikan semua field sudah terisi dengan benar!')
          .show(context);
      return;
    }

    await componentRM.setState((s) => s.componentChange = true);

    try {
      await componentFormRM.state.submitEditForm(widget.id);
    } catch (_) {
      // The repository folds failures by throwing. Swallowing it here keeps
      // the sheet open with the user's input intact instead of leaving a dead
      // spinner behind an uncaught async error.
      if (mounted) {
        ErrorMessenger('Gagal menyimpan komponen. Coba lagi.').show(context);
      }
      return;
    }

    if (!mounted) {
      return;
    }
    componentFormRM.state.cleanForm();
    Navigator.of(context).pop(true);
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => DeleteDialog(
        title: 'Hapus Komponen Nilai',
        content: 'Apakah Anda yakin ingin menghapus ${widget.componentName}?',
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await componentRM.setState((s) => s.componentChange = true);
    await componentRM.setState(
      (s) => s.deleteComponent(QueryComponent(id: widget.id)),
    );

    if (!mounted) {
      return;
    }
    componentFormRM.state.cleanForm();
    Navigator.of(context).pop(true);
  }

  /// Trims the `.0` off whole numbers so a weight of 7.5 reads `7.5` and 10
  /// reads `10`, not `10.0`.
  String _formatWeight(double weight) =>
      weight == weight.roundToDouble() ? weight.toStringAsFixed(0) : '$weight';

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
