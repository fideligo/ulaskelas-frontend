part of '_pages.dart';

<<<<<<< HEAD
class AddSemesterPage extends StatefulWidget {
  const AddSemesterPage({super.key});

  @override
  State<AddSemesterPage> createState() => _AddSemesterPageState();
}

class _AddSemesterPageState extends State<AddSemesterPage> {
  final userGen = int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;
  List<String> _selectableSemester = [];
  String? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _initSelectableSemesters();
  }

  void _initSelectableSemesters() {
    final semesters = semesterRM.state.semesters;
    final listOfSemester = <String>[
      '1',
      '2',
      'sp_${userGen + 1}',
      '3',
      '4',
      'sp_${userGen + 2}',
      '5',
      '6',
      'sp_${userGen + 3}',
      '7',
      '8',
      'sp_${userGen + 4}',
      '9',
      '10',
      'sp_${userGen + 5}',
      '11',
      '12',
    ];

    for (final givenSemester in listOfSemester) {
      final isExist = semesters.any(
        (element) => element.givenSemester == givenSemester,
      );
      if (!isExist) {
        _selectableSemester.add(givenSemester);
      }
    }
  }

  String _formatSemesterDisplay(String semester) {
    if (!semester.contains('sp')) {
      return 'Semester $semester';
    }
    final year = semester.split('_').last;
    return 'Semester Pendek 20$year';
  }

  void _onAutoFillPressed() {
    if (_selectedSemester == null) {
      ErrorMessenger('Pilih semester terlebih dahulu').show(context);
      return;
    }
    // Placeholder navigation for Auto-Fill
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigasi ke halaman Auto-Fill')),
    );
  }

  void _onManualFillPressed() {
    if (_selectedSemester == null) {
      ErrorMessenger('Pilih semester terlebih dahulu').show(context);
      return;
    }
    nav.push(
      SearchCourseCalculator(
        givenSemester: _selectedSemester!,
=======
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
>>>>>>> 99ee5f7ef868c5e0a4a3216e9eb39269fa9267fe
      ),
    );
  }

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseColors.white,
      appBar: AppBar(
        backgroundColor: BaseColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BaseColors.mineShaft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Semester',
              style: FontTheme.poppins14w700black().copyWith(
                fontSize: 16,
              ),
            ),
            const HeightSpace(2),
            Text(
              'Pilih cara menambah mata kuliah',
              style: FontTheme.poppins12w400black().copyWith(
                color: BaseColors.gray2,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: BaseColors.gray5,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
            DropdownButtonFormField2<String>(
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
                  borderSide:
                      const BorderSide(color: BaseColors.gray2, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: BaseColors.gray2, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: BaseColors.gray2, width: 2),
                ),
                filled: true,
                fillColor: BaseColors.white,
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 250,
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
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 16),
              ),
              value: _selectedSemester,
              items: _selectableSemester.map((String semester) {
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
                  _selectedSemester = newValue;
                });
              },
            ),
            const HeightSpace(24),
            _buildAutoFillCard(),
            const HeightSpace(16),
            _buildManualFillCard(),
          ],
        ),
=======
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
>>>>>>> 99ee5f7ef868c5e0a4a3216e9eb39269fa9267fe
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildAutoFillCard() {
    return GestureDetector(
      onTap: _onAutoFillPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF162456), Color(0xFF5D0EC0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👍', style: TextStyle(fontSize: 12)),
                  const WidthSpace(6),
                  Text(
                    'Recommended',
                    style: FontTheme.poppins12w600black().copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const HeightSpace(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Fallback to normal logo
                      width: 48,
                      height: 48,
                      color: BaseColors.goldenrod,
                    ),
                    const HeightSpace(4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'SIAK ',
                            style: FontTheme.poppins10w700black().copyWith(
                              color: BaseColors.white,
                              fontSize: 9,
                            ),
                          ),
                          TextSpan(
                            text: 'NG',
                            style: FontTheme.poppins10w700black().copyWith(
                              color: BaseColors.goldenrod,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const WidthSpace(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Fill dari SIAK',
                        style: FontTheme.poppins16w700black().copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const HeightSpace(8),
                      Text(
                        'Matkul yang kamu pilih di IRS semester ini langsung masuk otomatis. Tidak perlu input manual.',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                      const HeightSpace(16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C950)
                              .withOpacity(0.3), // Exact color requested
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              color: Color(0xFFB9F8CF), // Exact color requested
                              size: 14,
                            ),
                            const WidthSpace(6),
                            Text(
                              'Terintegrasi SSO UI',
                              style: FontTheme.poppins10w700black().copyWith(
                                color: const Color(0xFFB9F8CF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualFillCard() {
    return GestureDetector(
      onTap: _onManualFillPressed,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF), // Light purple bg
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE2D9FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Manual',
                style: FontTheme.poppins12w700black().copyWith(
                  color: const Color(0xFF4921B8),
                  fontSize: 11,
                ),
              ),
            ),
            const HeightSpace(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2D9FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF4921B8),
                      size: 24,
                    ),
                  ),
                ),
                const WidthSpace(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Matkul Manual',
                        style: FontTheme.poppins16w700black(),
                      ),
                      const HeightSpace(8),
                      Text(
                        'Cari dan pilih beberapa matkul sekaligus. Cocok jika matkul tidak terdaftar di SIAK atau mau custom',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: BaseColors.gray1,
                          height: 1.4,
                        ),
                      ),
                      const HeightSpace(16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2D9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_box_outlined,
                              color: Color(0xFF4921B8),
                              size: 14,
                            ),
                            const WidthSpace(6),
                            Text(
                              'Multi-Select Sekaligus',
                              style: FontTheme.poppins10w700black().copyWith(
                                color: const Color(0xFF4921B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
=======
  /// Both cards are always tappable so the warning can explain what is
  /// missing, rather than leaving a dead-looking card with no feedback.
  void _chooseFillMethod(Future<void> Function(String) goToPage) {
    final givenSemester = addSemesterRM.state.selectedSemester;
    if (givenSemester == null) {
      WarningMessenger('Pilih semester terlebih dahulu').show(context);
      return;
    }
    goToPage(givenSemester);
>>>>>>> 99ee5f7ef868c5e0a4a3216e9eb39269fa9267fe
  }
}
