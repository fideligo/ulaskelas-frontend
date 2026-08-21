part of '_pages.dart';

class KonfirmasiSemesterPage extends StatefulWidget {
  const KonfirmasiSemesterPage({
    required this.givenSemester,
    required this.selectedCourses,
    this.slcmSessionId,
    super.key,
  });

  final String givenSemester;
  final List<CourseModel> selectedCourses;

  /// Set only by the SLCM autofill flow. Null means manual fill, which keeps
  /// every existing behaviour on this page.
  final String? slcmSessionId;

  @override
  State<KonfirmasiSemesterPage> createState() => _KonfirmasiSemesterPageState();
}

class _KonfirmasiSemesterPageState extends State<KonfirmasiSemesterPage> {
  late List<CourseModel> _courses;

  /// Only ever set by the SLCM branch. Manual fill leaves it false for the
  /// life of the page, so its button behaves exactly as before.
  bool _isSubmitting = false;

  /// Splits the two ways onto this page. Adding a course by hand still has
  /// nowhere to go on the SLCM path, and removing one is recorded back on
  /// `AutoFillState` instead of the manual-fill basket.
  bool get _isSlcmFlow => widget.slcmSessionId != null;

  @override
  void initState() {
    super.initState();
    _courses = List.from(widget.selectedCourses);
  }

  int get _totalSks {
    return _courses.fold(0, (sum, course) => sum + (course.sks ?? 0));
  }

  int get _userGeneration =>
      int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;

  String _getSemesterPill() {
    return academicTermLabel(widget.givenSemester, _userGeneration);
  }

  void _onTambahMatkul() {
    Navigator.of(context).pop();
  }

  /// Drops a course from the list about to be submitted.
  ///
  /// The removal is mirrored onto whichever state fed this page so going back
  /// a step shows the same list, not the one from before the deletion.
  ///
  /// On the SLCM path this is presentational until the backend accepts an
  /// exclusion payload: confirm imports every course the scrape matched, so a
  /// course removed here is still written. See
  /// `slcm_autofill_remote_data_source.dart`.
  void _onDeleteCourse(CourseModel course) {
    setState(() {
      _courses.remove(course);
    });
    if (_isSlcmFlow) {
      autoFillRM.state.removeById(course.id);
      return;
    }
    manualFillRM.state.unselect(course);
  }

  Future<void> _onBuatSemester() async {
    if (_courses.isEmpty) {
      ErrorMessenger('Daftar mata kuliah tidak boleh kosong').show(context);
      return;
    }

    final slcmSessionId = widget.slcmSessionId;
    if (slcmSessionId != null) {
      await _confirmSlcmImport(slcmSessionId);
      return;
    }

    // First create the semester if it doesn't exist yet
    await semesterRM.state.postSemester([widget.givenSemester]);

    // Then add the selected courses to it
    await calculatorRM.state.postCalculator(_courses, widget.givenSemester);

    // Clear the manual-fill basket so it's fresh next time
    manualFillRM.state.reset();

    // Refresh semester state so Home is updated
    await semesterRM.state.retrieveData();

    // Navigate back to home calculator (main page)
    nav.popUntil(RouteName.mainPage);
  }

  /// The SLCM path. One call does the whole import server-side, so there is no
  /// postSemester/postCalculator pair here — confirm creates the semester rows
  /// itself from the preview it already holds.
  Future<void> _confirmSlcmImport(String sessionId) async {
    setState(() => _isSubmitting = true);
    try {
      await autoFillRM.state.confirm(sessionId);

      // Refresh so Home and the calculator list show the imported semester.
      await semesterRM.state.retrieveData();

      if (!mounted) {
        return;
      }
      SuccessMessenger('Semester berhasil dibuat dari SLCM').show(context);
      nav.popUntil(RouteName.mainPage);
    } on Failure catch (failure) {
      if (!mounted) {
        return;
      }
      // Left on the page so the student can retry without re-scraping.
      setState(() => _isSubmitting = false);
      ErrorMessenger(
        failure.message ?? 'Gagal mengimpor mata kuliah dari SLCM.',
      ).show(context);
    }
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
                semesterFullLabel(widget.givenSemester),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BaseColors.white,
        boxShadow: BoxShadowDecorator().defaultShadow(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FacultyLogo(
            code: course.code,
            facultyName: course.facultyName,
          ),
          const WidthSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name ?? '-',
                  style: FontTheme.poppins14w600black(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const HeightSpace(3),
                Text(
                  courseSubtitle(
                    sks: course.sks,
                    codeDesc: course.codeDesc,
                    code: course.code,
                  ),
                  style: FontTheme.poppins12w600black(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const WidthSpace(8),
          IconButton(
            onPressed: () => _onDeleteCourse(course),
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
          // Adding a course by hand has nowhere to go on the SLCM path — the
          // import comes from the scrape, not from this list.
          if (!_isSlcmFlow) ...[
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
          ],
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF4921B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Null only while an SLCM confirm is in flight; manual fill never
            // sets `_isSubmitting`, so its button is unchanged.
            onPressed: _isSubmitting ? null : _onBuatSemester,
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
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
