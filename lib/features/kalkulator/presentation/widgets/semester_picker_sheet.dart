part of '_widgets.dart';

/// Asks which semester a set of manually picked courses belongs to.
///
/// Split out of `AddSemesterPage` when the semester stopped being chosen up
/// front. Autofill derives its own target from the semester SLCM scraped, so
/// only the manual path still has to ask — and asking here keeps the question
/// next to the one flow that needs an answer.
///
/// Resolves to the chosen `given_semester`, or null when the sheet is
/// dismissed without confirming.
class SemesterPickerSheet extends StatefulWidget {
  const SemesterPickerSheet._({required this.semesters});

  /// The `given_semester` values still free, in the order they are offered.
  final List<String> semesters;

  static Future<String?> show(
    BuildContext context, {
    required List<String> semesters,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      // The dropdown overlay needs room to open past half height.
      isScrollControlled: true,
      // Transparent here, opaque in the child. `showModalBottomSheet` takes no
      // `surfaceTintColor` on this Flutter version, so a background passed
      // here would still be tinted by Material 3.
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => SemesterPickerSheet._(semesters: semesters),
    );
  }

  @override
  State<SemesterPickerSheet> createState() => _SemesterPickerSheetState();
}

class _SemesterPickerSheetState extends State<SemesterPickerSheet> {
  String? _selected;

  /// `sp_24` -> `Semester Pendek 2024`, `5` -> `Semester 5`.
  ///
  /// Not [semesterFullLabel]: the short-semester suffix here is built from the
  /// intake year, which is two digits when the profile reports one (`sp_24`).
  /// That label expands the suffix verbatim and would read `Semester Pendek
  /// 24`.
  String _formatSemesterDisplay(String semester) {
    if (!semester.contains('sp')) {
      return 'Semester $semester';
    }
    final yearStr = semester.split('_').last;
    final year = int.tryParse(yearStr) ?? 0;
    if (year < 100) {
      return 'Semester Pendek 20${year.toString().padLeft(2, '0')}';
    }
    return 'Semester Pendek $year';
  }

  void _onConfirm() {
    final selected = _selected;
    if (selected == null) {
      return;
    }
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Sized rather than wrapped to the content on purpose.
      //
      // `dropdown_button2` opens the menu downward from the field, then clamps
      // it into the screen: `getMenuLimits` sets `menuBottom = bottomLimit`
      // and walks `menuTop` back up whenever the menu would overflow. A
      // content-sized sheet is only ~250px tall, so the field sat near the
      // bottom edge and the menu had nowhere to go — it was pinned to the
      // bottom, covering the field it belongs to. Reserving half the viewport
      // lifts the field far enough that the menu opens beneath it normally.
      height: MediaQuery.of(context).size.height * 0.5,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: BaseColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1, thickness: 1, color: BaseColors.gray5),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester',
                      style: FontTheme.poppins14w700black().copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const HeightSpace(8),
                    _buildDropdown(),
                  ],
                ),
              ),
              // Holds the button against the bottom of the reserved space
              // instead of leaving it floating under the field. Not `Spacer`:
              // `ristek_material_component` exports one of its own, so the
              // name is ambiguous in this library.
              const Expanded(child: SizedBox.shrink()),
              _buildConfirmButton(),
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
          Text('Pilih Semester', style: FontTheme.poppins16w700black()),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            color: BaseColors.neutral100,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            // No result: dismissed without choosing, so the caller stays put.
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField2<String>(
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.only(
          left: 3,
          right: 16,
          top: 12,
          bottom: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BaseColors.gray2, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BaseColors.gray2, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BaseColors.gray2, width: 2),
        ),
        filled: true,
        fillColor: BaseColors.white,
      ),
      dropdownStyleData: DropdownStyleData(
        // Fits under the field on a normal phone once the sheet reserves half
        // the viewport, so the menu scrolls internally rather than being
        // clamped against the bottom edge. The list runs to 17 semesters, so
        // it is always scrolling anyway.
        maxHeight: 200,
        elevation: 0,
        offset: const Offset(0, -4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BaseColors.gray2, width: 2),
          color: BaseColors.white,
        ),
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(40),
          thickness: MaterialStateProperty.all(6),
          thumbVisibility: MaterialStateProperty.all(true),
          thumbColor: MaterialStateProperty.all(BaseColors.gray2),
          crossAxisMargin: 8,
          mainAxisMargin: 8,
        ),
      ),
      hint: Text(
        'Pilih Semester',
        style: FontTheme.poppins12w400black().copyWith(
          color: BaseColors.gray2,
          fontSize: 14,
        ),
      ),
      iconStyleData: const IconStyleData(
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: BaseColors.purpleHearth,
        ),
        openMenuIcon: Icon(
          Icons.keyboard_arrow_up_rounded,
          color: BaseColors.purpleHearth,
        ),
      ),
      menuItemStyleData: const MenuItemStyleData(
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
      value: _selected,
      items: widget.semesters.map((String semester) {
        return DropdownMenuItem<String>(
          value: semester,
          child: Text(
            _formatSemesterDisplay(semester),
            style: FontTheme.poppins12w400black().copyWith(
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selected = newValue;
        });
      },
    );
  }

  /// Inert until a semester is picked — the manual fill page takes one as a
  /// required argument, so there is nothing to route with yet.
  Widget _buildConfirmButton() {
    final isEnabled = _selected != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isEnabled ? BaseColors.purpleHearth : BaseColors.gray4,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isEnabled ? _onConfirm : null,
              child: Center(
                child: Text(
                  'Lanjut',
                  style: FontTheme.poppins14w600black().copyWith(
                    color: isEnabled ? BaseColors.white : BaseColors.gray2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
