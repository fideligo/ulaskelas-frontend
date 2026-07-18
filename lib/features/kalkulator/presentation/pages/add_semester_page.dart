part of '_pages.dart';

/// Picks a semester, then how to fill it: straight from SIAK or by hand.
class AddSemesterPage extends StatefulWidget {
  const AddSemesterPage({
    super.key,
  });

  @override
  _AddSemesterPageState createState() => _AddSemesterPageState();
}

class _AddSemesterPageState extends BaseStateful<AddSemesterPage> {
  @override
  void init() {
    // Entering the page always starts from a blank choice.
    addSemesterRM.state.reset();
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return BaseAppBar(
      label: 'Tambah Semester',
      centerTitle: false,
      elevation: 0,
      style: FontTheme.poppins18w700black(),
    );
  }

  @override
  Widget buildNarrowLayout(BuildContext context, SizingInformation sizeInfo) {
    return SafeArea(
      child: OnBuilder<AddSemesterState>.all(
        listenTo: addSemesterRM,
        onIdle: _buildForm,
        onWaiting: _buildForm,
        onError: (dynamic error, refresh) => _buildForm(),
        onData: (_) => _buildForm(),
      ),
    );
  }

  @override
  Widget buildWideLayout(BuildContext context, SizingInformation sizeInfo) {
    return buildNarrowLayout(context, sizeInfo);
  }

  /// Leave the pop to whoever triggered it — the app bar arrow uses
  /// [BaseAppBar]'s default, hardware back uses the framework. Popping here as
  /// well would pop the dashboard underneath too.
  @override
  Future<bool> onBackPressed() async {
    return true;
  }

  Widget _buildForm() {
    final state = addSemesterRM.state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: [
        Text(
          'Pilih cara menambah mata kuliah',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
        ),
        const HeightSpace(24),
        Text(
          'Semester',
          style: FontTheme.poppins14w600black(),
        ),
        const HeightSpace(8),
        _buildDropdown(state),
        const HeightSpace(24),
        CardAutoFillOption(
          onTap: () => _chooseFillMethod(nav.goToAutoFillPage),
        ),
        const HeightSpace(14),
        CardManualFillOption(
          onTap: () => _chooseFillMethod(nav.goToManualFillPage),
        ),
      ],
    );
  }

  Widget _buildDropdown(AddSemesterState state) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        value: state.selectedSemester,
        hint: Text(
          'Click here to choose',
          style: FontTheme.poppins14w400black().copyWith(
            color: BaseColors.gray3,
          ),
        ),
        items: state.options
            .map(
              (givenSemester) => DropdownMenuItem(
                value: givenSemester,
                child: Text(
                  semesterFullLabel(givenSemester),
                  style: FontTheme.poppins14w400black(),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => addSemesterRM.state.select(value),
        buttonStyleData: ButtonStyleData(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: BaseColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BaseColors.gray4),
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: BaseColors.gray2,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 320,
          decoration: BoxDecoration(
            color: BaseColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        menuItemStyleData: const MenuItemStyleData(height: 44),
      ),
    );
  }

  /// Both cards are always tappable so the warning can explain what is
  /// missing, rather than leaving a dead-looking card with no feedback.
  void _chooseFillMethod(Future<void> Function(String) goToPage) {
    final givenSemester = addSemesterRM.state.selectedSemester;
    if (givenSemester == null) {
      WarningMessenger('Pilih semester terlebih dahulu').show(context);
      return;
    }
    goToPage(givenSemester);
  }
}
