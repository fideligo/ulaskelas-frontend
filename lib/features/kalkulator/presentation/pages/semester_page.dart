part of '_pages.dart';

class SemesterPage extends StatefulWidget {
  const SemesterPage({
    required this.givenSemester,
    required this.semesterGPA,
    required this.totalSKS,
    super.key,
  });

  final String? givenSemester;
  final double? semesterGPA;
  final int? totalSKS;

  @override
  _SemesterPageState createState() => _SemesterPageState();
}

class _SemesterPageState extends BaseStateful<SemesterPage> {
  String get semesterName {
    if (widget.givenSemester!.contains('sp')) {
      return 'SP ${widget.givenSemester!.substring(3)}';
    }
    return 'Semester ${widget.givenSemester}';
  }

  @override
  void init() {
    StateInitializer(
      rIndicator: refreshIndicatorKey!,
      state: calculatorRM.state.getCondition(),
      cacheKey: calculatorRM.state.cacheKey!,
    ).initialize();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Pref.getBool('doneAppTour') == false ||
          Pref.getBool('doneAppTour') == null && !backFromNavbarProfile) {
        showcaseSemesterPage();
      }
    });
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: BaseColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BaseColors.mineShaft),
        onPressed: onBackPressed,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Semester',
            style: FontTheme.poppins14w700black().copyWith(
              fontSize: 16,
            ),
          ),
          const HeightSpace(2),
          Text(
            'Pastikan sudah sesuai sebelum mengedit',
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
    );
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute();
  }

  @override
  Widget buildNarrowLayout(BuildContext context, SizingInformation sizeInfo) {
    return ShowCaseWidget(
      builder: (context) {
        semesterContext = context;
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: retrieveData,
            key: refreshIndicatorKey,
            child: OnBuilder<CalculatorState>.all(
              listenTo: calculatorRM,
              onWaiting: WaitingView.new,
              onIdle: WaitingView.new,
              onError: (dynamic error, refresh) => Text(error.toString()),
              onData: (data) {
                final calculators = data.calculators;
                return Container(
                  color: BaseColors.white,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSemesterCard(calculators.length),
                              const HeightSpace(24),
                              if (calculators.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          Ilustration.notfound,
                                          width: sizeInfo.screenSize.width * .6,
                                        ),
                                        const HeightSpace(20),
                                        Text(
                                          'Belum Ada Mata Kuliah yang Tersimpan',
                                          style: FontTheme.poppins14w700black()
                                              .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: calculators.length,
                                  itemBuilder: (context, index) {
                                    final calculator = calculators[index];
                                    if (index == 0 &&
                                        (Pref.getBool('doneAppTour') == false ||
                                            Pref.getBool('doneAppTour') ==
                                                null)) {
                                      return ShowcaseWrapper(
                                        showcaseKey: inAppTourKeys.courseCardGC,
                                        targetPadding: const EdgeInsets.all(12),
                                        targetBorderRadius:
                                            BorderRadius.circular(10),
                                        onTargetClick: () async {
                                          ShowCaseWidget.of(context).dismiss();
                                          backToMatkulCalcPage = () => nav.push(
                                                MockCalculatorComponentPage(
                                                  givenSemester:
                                                      widget.givenSemester!,
                                                  courseId:
                                                      calculator.courseId!,
                                                  calculatorId: calculator.id!,
                                                  courseName:
                                                      calculator.courseName!,
                                                  totalScore:
                                                      calculator.totalScore!,
                                                  totalPercentage: calculator
                                                      .totalPercentage!,
                                                  courseSKS:
                                                      calculator.courseSKS!,
                                                ),
                                              );
                                          backFromNavbarProfile = false;
                                          backToMatkulCalcPage();
                                        },
                                        container: courseCardGCShowcase(
                                          context,
                                          calculator,
                                          widget.givenSemester!,
                                        ),
                                        child: CardCalculator(
                                          model: calculator,
                                          givenSemester: widget.givenSemester!,
                                          onTap: () => nav.push<void>(
                                            MockCalculatorComponentPage(
                                              givenSemester:
                                                  widget.givenSemester!,
                                              courseId: calculator.courseId!,
                                              calculatorId: calculator.id!,
                                              courseName:
                                                  calculator.courseName!,
                                              totalScore:
                                                  calculator.totalScore!,
                                              totalPercentage:
                                                  calculator.totalPercentage!,
                                              courseSKS: calculator.courseSKS!,
                                            ),
                                            RouteName.calculatorComponent,
                                          ),
                                        ),
                                      );
                                    }
                                    return CardCalculator(
                                      model: calculator,
                                      givenSemester: widget.givenSemester!,
                                      onTap: () => nav.push<void>(
                                        CalculatorComponentPage(
                                          givenSemester: widget.givenSemester!,
                                          courseId: calculator.courseId!,
                                          calculatorId: calculator.id!,
                                          courseName: calculator.courseName!,
                                          totalScore: calculator.totalScore!,
                                          totalPercentage:
                                              calculator.totalPercentage!,
                                          courseSKS: calculator.courseSKS!,
                                        ),
                                        RouteName.calculatorComponent,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomActions(),
                    ],
                  ),
                );
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
    nav.pop();
    calculatorRM.state.calculators.clear();
    await semesterRM.state.retrieveData();
    return true;
  }

  Future<void> retrieveData() async {
    await calculatorRM.setState(
      (s) => s.retrieveData(widget.givenSemester!),
    );
  }

  int get _userGeneration =>
      int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;

  String _getSemesterPill() {
    return academicTermLabel(widget.givenSemester ?? '0', _userGeneration);
  }

  Widget _buildSemesterCard(int totalCourses) {
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
                semesterFullLabel(widget.givenSemester ?? '0'),
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
                '${widget.totalSKS ?? 0}',
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
            '$totalCourses Mata Kuliah',
            style: FontTheme.poppins12w400black().copyWith(
              color: Colors.white.withOpacity(0.8),
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
            onPressed: () =>
                nav.goToSearchCourseCalculatorPage(widget.givenSemester!),
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
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: BaseColors.error, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 250));
              await showDialog(
                context: context,
                builder: (context) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: DeleteDialog(
                    title: 'Apakah Anda yakin?',
                    content: 'Data yang dihapus tidak dapat dikembalikan',
                    onConfirm: () async {
                      nav
                        ..pop()
                        ..pop();
                      await semesterRM.setState(
                        (s) => s.deleteSemester(
                          query: QuerySemester(
                            givenSemester: widget.givenSemester,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: Text(
              'Hapus Semester Ini',
              style: FontTheme.poppins14w600black().copyWith(
                color: BaseColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
