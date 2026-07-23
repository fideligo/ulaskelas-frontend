part of '_widgets.dart';

/// The exact palette this sheet is specified in.
///
/// Held locally rather than in [BaseColors] because these are design-signed
/// values for the sheet specifically — the nearest tokens differ (`error` is
/// `#EB5757`, not `#FB2C36`) and silently drifting onto them would be wrong.
abstract class _SheetColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFF5038BC);
  static const delete = Color(0xFFFB2C36);

  /// Marks the number as Ruby's, not the student's.
  static const ruby = LinearGradient(
    colors: [Color(0xFFD293FF), Color(0xFF3F4FB4)],
  );
}

/// What the user did before the sheet closed.
enum KomponenSheetAction {
  /// An existing component's scores were edited.
  saved,

  /// A new component was created.
  added,

  /// The user confirmed deletion. The sheet does **not** delete — the caller
  /// owns the call, so the success toast is pushed onto a navigator the sheet
  /// is no longer sitting on. See [_KomponenBottomSheetState._onDelete].
  deleted,
}

/// The sheet's outcome, handed back to the caller on pop.
///
/// Carries [name] because the confirmation copy quotes the component, and by
/// the time the caller runs, the shared form state has already been cleared.
class KomponenSheetResult {
  const KomponenSheetResult({required this.action, required this.name});

  final KomponenSheetAction action;
  final String name;

  /// The line shown in the page's confirmation banner.
  String get message {
    switch (action) {
      case KomponenSheetAction.saved:
        return 'Nilai $name tersimpan! Rekomendasi diupdate';
      case KomponenSheetAction.added:
        return 'Komponen $name tersimpan! Rekomendasi diupdate';
      case KomponenSheetAction.deleted:
        return 'Komponen $name berhasil dihapus!';
    }
  }
}

/// Add and edit for a grade component, as a sheet over the detail page.
///
/// One widget for both modes: the two flows differ only in their title, their
/// primary label, whether delete is offered, and which submit call runs, so
/// splitting them would duplicate the whole nullable-grade form.
///
/// The sheet deliberately pushes no routes of its own. Every messenger in this
/// app is a `Flushbar`, and a Flushbar is a route: showing one puts it on top
/// of the sheet, and the sheet's own `Navigator.pop` would then pop the toast
/// instead of the sheet — which then trips
/// `entry.currentState == _RouteLifecycle.popping` when the toast's 1800ms
/// timer tries to dismiss a route that is already gone. So failures render
/// inline here, and success toasts belong to the caller.
class KomponenBottomSheet extends StatefulWidget {
  const KomponenBottomSheet._({
    required this.isEdit,
    this.componentId,
    this.calculatorId,
    this.componentName,
    this.componentWeight,
  });

  final bool isEdit;

  /// Edit mode only — the subcomponent being edited.
  final int? componentId;

  /// Add mode only — the calculator the new component hangs off.
  final int? calculatorId;

  final String? componentName;
  final double? componentWeight;

  /// Resolves to the outcome, or null when the user simply dismissed it.
  static Future<KomponenSheetResult?> showEdit(
    BuildContext context, {
    required int id,
    required String componentName,
    required double componentWeight,
  }) {
    return _show(
      context,
      KomponenBottomSheet._(
        isEdit: true,
        componentId: id,
        componentName: componentName,
        componentWeight: componentWeight,
      ),
    );
  }

  static Future<KomponenSheetResult?> showAdd(
    BuildContext context, {
    required int calculatorId,
  }) {
    return _show(
      context,
      KomponenBottomSheet._(
        isEdit: false,
        calculatorId: calculatorId,
      ),
    );
  }

  static Future<KomponenSheetResult?> _show(
    BuildContext context,
    KomponenBottomSheet sheet,
  ) {
    return showModalBottomSheet<KomponenSheetResult>(
      context: context,
      // Required for the sheet to grow past half height and to sit above the
      // keyboard once a field takes focus.
      isScrollControlled: true,
      // Transparent here, opaque in the child. `showModalBottomSheet` has no
      // `surfaceTintColor` parameter on this Flutter version — the sheet reads
      // it from `bottomSheetTheme`, so a background passed here would still be
      // tinted by Material 3. Painting the fill ourselves is what actually
      // guarantees #FFFFFF.
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => sheet,
    );
  }

  @override
  State<KomponenBottomSheet> createState() => _KomponenBottomSheetState();
}

class _KomponenBottomSheetState extends State<KomponenBottomSheet> {
  bool _scoresExpanded = true;

  /// Rendered in the sheet rather than shown as a toast — see the note on
  /// [KomponenBottomSheet] for why this must not be a Flushbar.
  String? _formError;

  bool get _isEdit => widget.isEdit;

  String get _title => _isEdit ? 'Edit Komponen' : 'Tambah Komponen';

  String get _primaryLabel => _isEdit ? 'Simpan Nilai' : 'Tambah Komponen';

  @override
  void initState() {
    super.initState();
    componentFormRM.setState((s) => s.cleanForm());

    if (!_isEdit) {
      // cleanForm already leaves an empty name, empty weight, frequency 1 and
      // a single blank score controller, which is the whole add-mode default.
      return;
    }

    componentFormRM.state.nameController.text = widget.componentName ?? '';
    componentFormRM.state.weightController.text =
        _formatWeight(widget.componentWeight ?? 0);
    componentFormRM.setState(
      (s) => s.retrieveDetailedComponent(
        QueryComponent(scoreComponentId: widget.componentId),
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
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: _SheetColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
          Text(_title, style: FontTheme.poppins16w700black()),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            color: BaseColors.neutral100,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            // No result: dismissed without saving, so the caller does nothing.
            onPressed: () => Navigator.of(context).pop(),
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
              child: Text('%', style: FontTheme.poppins14w700black()),
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
                            color: _SheetColors.delete,
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
                  _buildRubyPill(data, entered),
                ],
              ),
            ],
          ),
          const HeightSpace(6),
          const Divider(height: 1, thickness: 0.7, color: BaseColors.gray4),
        ],
      ),
    );
  }

  /// Ruby's number for one occurrence: what it scored if graded, what it still
  /// needs if not. The gradient on both border and digits is what marks it as
  /// Ruby's suggestion rather than the student's own input.
  Widget _buildRubyPill(ComponentFormState data, double? entered) {
    final value = entered ?? data.recommendedScore;
    final isOverMax = entered != null && entered > 200;
    final label = isOverMax ? '???' : _formatNumber(value);

    return Container(
      height: 38,
      width: 62,
      // The 1.2 inset is the border: the outer box paints the gradient, the
      // inner one covers all but its edge.
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: isOverMax ? null : _SheetColors.ruby,
        color: isOverMax ? BaseColors.danger : null,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _SheetColors.background,
          borderRadius: BorderRadius.circular(6.8),
        ),
        child: isOverMax
            ? Text(
                label,
                style: FontTheme.poppins12w500black().copyWith(
                  color: BaseColors.danger,
                ),
              )
            : GradientText(
                label,
                gradient: _SheetColors.ruby,
                style: FontTheme.poppins12w500black(),
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
          if (_formError != null) _buildFormError(_formError!),
          // Nothing to delete yet in add mode.
          if (_isEdit)
            InkWell(
              onTap: _onDelete,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Hapus Komponen',
                  style: FontTheme.poppins14w500black().copyWith(
                    color: _SheetColors.delete,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const HeightSpace(8),
          OnReactive(_buildPrimaryButton),
        ],
      ),
    );
  }

  Widget _buildFormError(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: _SheetColors.delete),
          const WidthSpace(6),
          Expanded(
            child: Text(
              message,
              style: FontTheme.poppins12w400black().copyWith(
                color: _SheetColors.delete,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final isLoading = componentFormRM.state.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _SheetColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : _onSave,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          _SheetColors.background,
                        ),
                      ),
                    )
                  : Text(
                      _primaryLabel,
                      style: FontTheme.poppins14w600black().copyWith(
                        color: _SheetColors.background,
                      ),
                    ),
            ),
          ),
        ),
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
      setState(
        () => _formError = 'Pastikan semua field sudah terisi dengan benar!',
      );
      return;
    }

    setState(() => _formError = null);

    if (!_isEdit) {
      MixpanelService.track('calculator_add_course_component');
    }

    await componentRM.setState((s) => s.componentChange = true);

    try {
      if (_isEdit) {
        await componentFormRM.state.submitEditForm(widget.componentId!);
      } else {
        await componentFormRM.state.submitForm(widget.calculatorId!);
      }
    } catch (_) {
      // The repository folds failures by throwing. Reporting inline keeps the
      // sheet open with the user's input intact, and — unlike a toast — pushes
      // no route that a later successful save would then pop by mistake.
      if (mounted) {
        setState(() => _formError = 'Gagal menyimpan komponen. Coba lagi.');
      }
      return;
    }

    if (!mounted) {
      return;
    }

    // Read before cleanForm() — it clears the controller this name comes from.
    final name = componentFormRM.state.nameController.text.trim();

    componentFormRM.state.cleanForm();
    Navigator.of(context).pop(
      KomponenSheetResult(
        action:
            _isEdit ? KomponenSheetAction.saved : KomponenSheetAction.added,
        name: name,
      ),
    );
  }

  /// Confirms, then closes and hands the deletion to the caller.
  ///
  /// The API call deliberately does not run here. `deleteComponent` shows a
  /// `SuccessMessenger`, which pushes a Flushbar route on top of this sheet;
  /// popping afterwards would take the toast rather than the sheet and crash
  /// the navigator when the toast's timer expires. Closing first means the
  /// toast lands on the detail page's navigator with nothing above it.
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

    componentFormRM.state.cleanForm();
    Navigator.of(context).pop(
      KomponenSheetResult(
        action: KomponenSheetAction.deleted,
        name: widget.componentName ?? 'Komponen',
      ),
    );
  }

  /// Trims the `.0` off whole numbers so a weight of 7.5 reads `7.5` and 10
  /// reads `10`, not `10.0`.
  String _formatWeight(double weight) =>
      weight == weight.roundToDouble() ? weight.toStringAsFixed(0) : '$weight';

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}
