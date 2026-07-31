part of '_pages.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    super.key,
  });

  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends BaseStateful<CalculatorPage> {
  @override
  void init() {
    StateInitializer(
      rIndicator: refreshIndicatorKey!,
      state: semesterRM.state.getCondition(),
      cacheKey: semesterRM.state.cacheKey!,
    ).initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(Ilustration.login), context);
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute(
      backgroundColor: BaseColors.white,
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return BaseAppBar(
      hasLeading: false,
      label: 'Kalkulator',
      centerTitle: false,
      elevation: 0,
      style: FontTheme.poppins20w700black(),
    );
  }

  @override
  Widget buildNarrowLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return ShowCaseWidget(
      builder: (context) {
        calculatorContext = context;
        return SafeArea(
          child: RefreshIndicator(
            key: refreshIndicatorKey,
            onRefresh: retrieveData,
            child: OnBuilder<SemesterState>.all(
              listenTo: semesterRM,
              onIdle: WaitingView.new,
              onWaiting: WaitingView.new,
              onError: (dynamic error, refresh) => _buildError(),
              onData: (data) {
                if (data.semesters.isEmpty) {
                  return _buildEmptyState(context, sizeInfo);
                }
                return _buildDashboard(context, data);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildWideLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return buildNarrowLayout(context, sizeInfo);
  }

  @override
  Future<bool> onBackPressed() async {
    return true;
  }

  Future<void> retrieveData() async {
    await semesterRM.setState((s) => s.retrieveData());
    if (semesterRM.state.autoFillSemesters.isEmpty) {
      await semesterRM.setState((s) => s.retrieveDataForAutoFillSemesters());
    }
  }

  Future<void> showAutoFillSemesterDialog(BuildContext context) async {
    final availableSemesters = semesterRM.state.availableSemestersToFill;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AutoFillSemesterDialog(
          availableSemesters: availableSemesters,
        );
      },
    );
  }

  /// Refresh on the way back so a semester added there shows up here.
  Future<void> openAddSemesterPage() async {
    await nav.goToAddSemesterPage();
    await retrieveData();
  }

  Widget _buildDashboard(BuildContext context, SemesterState data) {
    final activeSemester = data.activeSemester;

    // The in-app tour walks the user back here from the navbar, so it needs to
    // know which semester the card on screen opens.
    if (activeSemester != null) {
      targetSemester = {
        'givenSemester': activeSemester.givenSemester,
        'semesterGPA': activeSemester.semesterGPA,
        'totalSKS': activeSemester.totalSKS,
      };
      openSemesterPage = () => _openSemester(activeSemester);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ShowcaseWrapper(
          showcaseKey: inAppTourKeys.filledSemesterGC,
          targetPadding: const EdgeInsets.all(10),
          targetBorderRadius: BorderRadius.circular(16),
          container: filledCalcGCShowcase(context),
          child: CardGpaSummary(
            gpa: data.cumulativeGPADisplay,
            badge: data.activeSemesterBadge,
            isHidden: data.isGpaHidden,
            onToggleVisibility: () => semesterRM.state.toggleGpaVisibility(),
          ),
        ),
        const HeightSpace(24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Semester Aktif',
                style: FontTheme.poppins14w700black(),
              ),
            ),
            const WidthSpace(12),
            ShowcaseWrapper(
              showcaseKey: inAppTourKeys.emptySemesterGC,
              tooltipPosition: TooltipPosition.bottom,
              targetPadding: const EdgeInsets.all(8),
              targetBorderRadius: BorderRadius.circular(10),
              container: emptyCalcGCShowcase(context),
              child: _addSemesterButton(),
            ),
          ],
        ),
        const HeightSpace(14),
        if (activeSemester == null)
          _buildHint('Belum ada semester aktif.')
        else ...[
          ShowcaseWrapper(
            showcaseKey: inAppTourKeys.semesterCardGC,
            targetPadding: const EdgeInsets.all(10),
            targetBorderRadius: BorderRadius.circular(12),
            onTargetClick: () async {
              ShowCaseWidget.of(context).dismiss();
              await _openSemester(activeSemester);
            },
            container: semesterCardGCShowcase(context, activeSemester),
            child: CardActiveSemester(
              model: activeSemester,
              onTap: () => _openSemester(activeSemester),
            ),
          ),
          const HeightSpace(10),
          ..._buildActiveCourses(data, activeSemester),
        ],
        if (data.pastSemesters.isNotEmpty) ...[
          const HeightSpace(14),
          Text(
            'Semester Lalu',
            style: FontTheme.poppins14w700black(),
          ),
          const HeightSpace(14),
          ...data.pastSemesters.map(
            (semester) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CardPastSemester(
                model: semester,
                onTap: () => _openSemester(semester),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActiveCourses(
    SemesterState data,
    SemesterModel activeSemester,
  ) {
    if (data.activeCourses.isEmpty) {
      return [
        _buildHint(
          'Belum ada mata kuliah di semester ini. '
          'Tambahkan untuk mulai menghitung nilai kamu!',
          onTap: () => nav.goToManualFillPage(
            activeSemester.givenSemester!,
          ),
        ),
      ];
    }

    return data.activeCourses
        .map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CardActiveCourse(
              model: course,
              status: data.statusOf(course),
              onTap: () => _openCourse(activeSemester, course),
            ),
          ),
        )
        .toList();
  }

  Widget _buildEmptyState(BuildContext context, SizingInformation sizeInfo) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HeightSpace(sizeInfo.screenSize.height * .05),
          Image.asset(
            Ilustration.login,
            width: sizeInfo.screenSize.width * .50,
          ),
          const HeightSpace(20),
          ShowcaseWrapper(
            showcaseKey: inAppTourKeys.emptySemesterGC,
            tooltipPosition: TooltipPosition.bottom,
            targetPadding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            targetBorderRadius: BorderRadius.circular(8),
            container: emptyCalcGCShowcase(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Belum Ada Semester yang Tersimpan',
                  style: FontTheme.poppins14w700black().copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const HeightSpace(10),
                Text(
                  'Tambahkan komponen semester baru untuk '
                  'mulai menghitung nilai kamu!',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const HeightSpace(20),
                PrimaryButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  borderRadius: BorderRadius.circular(8),
                  width: double.infinity,
                  text: 'Tambah Semester',
                  backgroundColor: BaseColors.purpleHearth,
                  onPressed: openAddSemesterPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const HeightSpace(60),
        Text(
          'Gagal memuat data kalkulator.\nTarik ke bawah untuk mencoba lagi.',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHint(String message, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: BaseColors.gray5,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _addSemesterButton() {
    return GestureDetector(
      onTap: openAddSemesterPage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: BaseColors.purpleHearth,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_box_outlined,
              size: 15,
              color: BaseColors.white,
            ),
            const WidthSpace(7),
            Text(
              'Tambah Semester',
              style: FontTheme.poppins12w600black().copyWith(
                color: BaseColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refresh on the way back: adding a matkul or deleting the semester there
  /// changes the GPA and course list shown here.
  Future<void> _openSemester(SemesterModel semester) async {
    await nav.goToSemesterPage(
      givenSemester: semester.givenSemester!,
      semesterGPA: semester.semesterGPA ?? 0,
      totalSKS: semester.totalSKS ?? 0,
    );
    await retrieveData();
  }

  /// Refresh on the way back. The component page keeps `calculatorRM` current
  /// for the semester page, but this page reads [SemesterState] — so without a
  /// refetch a component added there leaves the GPA, the weight and the status
  /// badge here stale until a manual pull-to-refresh.
  Future<void> _openCourse(
    SemesterModel semester,
    CalculatorModel course,
  ) async {
    await nav.goToComponentCalculatorPage(
      givenSemester: semester.givenSemester!,
      calculatorId: course.id!,
      courseId: course.courseId!,
      courseName: course.courseName ?? '-',
      totalScore: course.totalScore ?? 0,
      totalPercentage: course.totalPercentage ?? 0,
      courseSKS: course.courseSKS ?? 0,
    );
    await retrieveData();
  }
}
