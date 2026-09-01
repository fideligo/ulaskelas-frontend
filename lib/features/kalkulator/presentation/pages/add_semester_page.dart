part of '_pages.dart';

class AddSemesterPage extends StatefulWidget {
  const AddSemesterPage({super.key});

  @override
  State<AddSemesterPage> createState() => _AddSemesterPageState();
}

class _AddSemesterPageState extends State<AddSemesterPage> {
  final userGen = int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;

  /// Semesters the student has not created yet, in offer order. Manual fill
  /// hands this to the picker sheet; autofill no longer reads it, since the
  /// backend decides which semester a scrape writes into.
  final List<String> _selectableSemester = [];

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

  /// Starts an autofill run.
  ///
  /// Nothing is picked here any more. The app used to guess the target as the
  /// earliest regular semester the student had not created yet; the backend
  /// now derives it from their NPM entry year and the running academic period
  /// and returns it on the session, so the guess — and the guard that refused
  /// to start once every regular semester existed — are both gone.
  void _onAutoFillPressed() {
    nav.goToAutoFillPage();
  }

  Future<void> _onManualFillPressed() async {
    if (_selectableSemester.isEmpty) {
      WarningMessenger('Semua semester sudah ditambahkan').show(context);
      return;
    }
    final semester = await SemesterPickerSheet.show(
      context,
      semesters: _selectableSemester,
    );
    // Dismissed without choosing — stay on this page.
    if (semester == null) {
      return;
    }
    // `nav` routes off a global navigator key, so no BuildContext is read
    // across the await above.
    await nav.goToManualFillPage(semester);
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
