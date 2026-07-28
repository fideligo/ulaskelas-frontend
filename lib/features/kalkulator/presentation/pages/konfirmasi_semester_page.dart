part of '_pages.dart';

class KonfirmasiSemesterPage extends StatefulWidget {
  const KonfirmasiSemesterPage({
    required this.givenSemester,
    required this.selectedCourses,
    super.key,
  });

  final String givenSemester;
  final List<CourseModel> selectedCourses;

  @override
  State<KonfirmasiSemesterPage> createState() => _KonfirmasiSemesterPageState();
}

class _KonfirmasiSemesterPageState extends State<KonfirmasiSemesterPage> {
  late List<CourseModel> _courses;

  @override
  void initState() {
    super.initState();
    _courses = List.from(widget.selectedCourses);
  }

  int get _totalSks {
    return _courses.fold(0, (sum, course) => sum + (course.sks ?? 0));
  }

  String _getSemesterPill() {
    // Temporary logic for Genap 2025/2026 / Ganjil 2025/2026 based on givenSemester
    final sem = int.tryParse(widget.givenSemester) ?? 0;
    if (sem % 2 == 0) {
      return 'Genap 2025/2026';
    } else {
      return 'Ganjil 2025/2026';
    }
  }

  void _onTambahMatkul() {
    Navigator.of(context).pop();
  }

  void _onBuatSemester() async {
    if (_courses.isEmpty) {
      ErrorMessenger('Daftar mata kuliah tidak boleh kosong').show(context);
      return;
    }

    // First create the semester if it doesn't exist yet
    await semesterRM.state.postSemester([widget.givenSemester]);

    // Then add the selected courses to it
    await calculatorRM.state.postCalculator(_courses, widget.givenSemester);

    // Clear search course state so it's fresh next time
    await searchCourseRM.setState((s) => s.clearSelectedCourses());

    // Refresh semester state so Home is updated
    await semesterRM.state.retrieveData();

    // Navigate back to home
    Navigator.of(context).popUntil((route) => route.isFirst);
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
              'Konfirmasi Semester',
              style: FontTheme.poppins14w700black().copyWith(
                fontSize: 16,
              ),
            ),
            const HeightSpace(2),
            Text(
              'Pastikan sudah sesuai sebelum membuat',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSemesterCard(),
                  const HeightSpace(24),
                  Text(
                    'Mata kuliah yang akan ditambahkan',
                    style: FontTheme.poppins14w700black(),
                  ),
                  const HeightSpace(12),
                  ..._courses
                      .map((course) => _buildCourseCard(course))
                      .toList(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSemesterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF644BE0), Color(0xFF5038BC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Semester ${widget.givenSemester}',
                style: FontTheme.poppins16w700black().copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getSemesterPill(),
                  style: FontTheme.poppins12w600black().copyWith(
                    color: const Color(0xFF4921B8),
                  ),
                ),
              ),
            ],
          ),
          const HeightSpace(4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_totalSks',
                style: FontTheme.poppins20w700black().copyWith(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              const WidthSpace(4),
              Text(
                'total SKS',
                style: FontTheme.poppins14w400black().copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const HeightSpace(4),
          Text(
            '${_courses.length} Mata Kuliah',
            style: FontTheme.poppins12w400black().copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BaseColors.gray5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png', // Dummy makara logo
            width: 50,
            height: 50,
          ),
          const WidthSpace(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name ?? '-',
                  style: FontTheme.poppins14w700black(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const HeightSpace(4),
                Row(
                  children: [
                    Text(
                      course.codeDesc != course.code && course.codeDesc?.isNotEmpty == true
                          ? '${course.sks ?? 0} SKS   ${course.codeDesc}   ${course.code ?? '-'}'
                          : '${course.sks ?? 0} SKS   ${course.code ?? '-'}',
                      style: FontTheme.poppins12w500black(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _courses.remove(course);
              });
              // Keep state in sync in case user goes back
              searchCourseRM.setState((s) => s.selectedCourses.remove(course));
            },
            icon: const Icon(
              Icons.delete_outline,
              color: BaseColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Color(0xFF4921B8), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _onTambahMatkul,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Color(0xFF4921B8)),
                const WidthSpace(8),
                Text(
                  'Tambah Matkul',
                  style: FontTheme.poppins14w600black().copyWith(
                    color: const Color(0xFF4921B8),
                  ),
                ),
              ],
            ),
          ),
          const HeightSpace(12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF4921B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _onBuatSemester,
            child: Text(
              'Buat Semester',
              style: FontTheme.poppins14w700black().copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
