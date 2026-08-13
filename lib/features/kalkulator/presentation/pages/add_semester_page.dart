part of '_pages.dart';

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
    final yearStr = semester.split('_').last;
    final year = int.tryParse(yearStr) ?? 0;
    if (year < 100) {
      return 'Semester Pendek 20${year.toString().padLeft(2, '0')}';
    }
    return 'Semester Pendek $year';
  }

  void _onAutoFillPressed() {
    if (_selectedSemester == null) {
      WarningMessenger('Pilih semester terlebih dahulu').show(context);
      return;
    }
    nav.goToAutoFillPage(_selectedSemester!);
  }

  void _onManualFillPressed() {
    if (_selectedSemester == null) {
      WarningMessenger('Pilih semester terlebih dahulu').show(context);
      return;
    }
    nav.goToManualFillPage(_selectedSemester!);
  }

  @override
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
            const HeightSpace(22),
            _buildManualFillCard(),
          ],
        ),
      ),
    );
  }

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
                      'assets/faculties/UI.png',
                      width: 48,
                      height: 48,
                    ),
                    const HeightSpace(4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'SL',
                            style: FontTheme.poppins10w700black().copyWith(
                              color: BaseColors.white,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: 'CM',
                            style: FontTheme.poppins10w700black().copyWith(
                              color: BaseColors.goldenrod,
                              fontSize: 16,
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
                        'Auto-Fill dari SLCM',
                        style: FontTheme.poppins16w700black().copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const HeightSpace(3),
                      Text(
                        'Matkul yang kamu pilih di IRS semester ini langsung masuk otomatis. Tidak perlu input manual.',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                          fontSize: 13,
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
                        style: FontTheme.poppins16w700black().copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const HeightSpace(3),
                      Text(
                        'Cari dan pilih beberapa matkul sekaligus. Cocok jika matkul tidak terdaftar di SLCM atau mau custom.',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: BaseColors.gray1,
                          height: 1.4,
                          fontSize: 13,
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
  }
}
