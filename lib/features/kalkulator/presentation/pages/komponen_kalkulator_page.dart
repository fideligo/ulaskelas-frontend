part of '_pages.dart';

class CalculatorComponentPage extends StatefulWidget {
  const CalculatorComponentPage({
    required this.givenSemester,
    required this.calculatorId,
    required this.courseId,
    required this.courseName,
    required this.totalScore,
    required this.totalPercentage,
    required this.courseSKS,
    super.key,
  });

  final String givenSemester;
  final int calculatorId;
  final int courseId;
  final String courseName;
  final double totalScore;
  final double totalPercentage;
  final int courseSKS;

  @override
  _CalculatorComponentPageState createState() =>
      _CalculatorComponentPageState();
}

class _CalculatorComponentPageState
    extends BaseStateful<CalculatorComponentPage> {
  /// Confirmation strip for the last add/edit/delete, cleared on a timer.
  KomponenSheetResult? _banner;
  Timer? _bannerTimer;

  @override
  void init() {
    retrieveData();
    calculatorComponentRM.state.loadCourseType(widget.courseId);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _showBanner(KomponenSheetResult result) {
    _bannerTimer?.cancel();
    setState(() => _banner = result);
    _bannerTimer = Timer(const Duration(seconds: 4), _dismissBanner);
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    if (mounted) {
      setState(() => _banner = null);
    }
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return BaseAppBar(
      label: widget.courseName,
      centerTitle: false,
      elevation: 0,
      style: FontTheme.poppins16w700black(),
      onBackPress: onBackPressed,
    );
  }

  @override
  Widget buildNarrowLayout(BuildContext context, SizingInformation sizeInfo) {
    final banner = _banner;

    return SafeArea(
      child: Column(
        children: [
          // Sits above the scroll view so it stays visible wherever the user
          // has scrolled to.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: banner == null
                ? const SizedBox(width: double.infinity)
                : ActionSuccessBanner(
                    message: banner.message,
                    onDismiss: _dismissBanner,
                  ),
          ),
          Expanded(
            child: RefreshIndicator(
              key: refreshIndicatorKey,
              onRefresh: retrieveData,
              child: OnBuilder<CalculatorComponentState>.all(
                listenTo: calculatorComponentRM,
                onIdle: WaitingView.new,
                onWaiting: WaitingView.new,
                onError: (dynamic error, refresh) => _buildError(),
                onData: _buildDetail,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWideLayout(BuildContext context, SizingInformation sizeInfo) {
    return buildNarrowLayout(context, sizeInfo);
  }

  @override
  Future<bool> onBackPressed() async {
    nav.pop();
    await calculatorRM.state.retrieveData(widget.givenSemester);
    return true;
  }

  Future<void> retrieveData() async {
    await calculatorComponentRM.setState(
      (s) => s.retrieveData(QueryComponent(calculatorId: widget.calculatorId)),
    );
  }

  Widget _buildDetail(CalculatorComponentState data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildCoursePills(data),
        const HeightSpace(16),
        // Ruby's prediction only means anything once the rubric is whole, so
        // below 100% the card is replaced by the setup reminder.
        if (data.hasFullWeight)
          CardTargetGrade(
            target: data.target,
            currentGrade: data.currentGrade,
            currentScore: data.currentScore,
            onTargetSelected: _changeTarget,
          )
        else
          SetupBobotReminderCard(totalWeight: data.totalWeight),
        const HeightSpace(20),
        const ComponentTableHeader(),
        const HeightSpace(10),
        if (data.breakdowns.isEmpty)
          _buildEmptyComponents()
        else
          ...data.breakdowns.map(
            (breakdown) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardComponentExpansion(
                breakdown: breakdown,
                isExpanded: data.isExpanded(breakdown),
                recommendation: data.recommendationFor(
                  score: breakdown.isFullyFilled ? breakdown.average : null,
                ),
                occurrenceRecommendation:
                    data.hasFullWeight ? data.recommendedScore : null,
                rubyEnabled: data.hasFullWeight,
                onTap: () =>
                    calculatorComponentRM.state.toggleExpanded(breakdown),
                onEdit: () => _editComponent(breakdown),
              ),
            ),
          ),
        const HeightSpace(20),
        _buildAddComponentButton(),
        const HeightSpace(28),
        Center(
          child: InkWell(
            onTap: _deleteCourse,
            child: Text(
              'Hapus Kalkulator Mata Kuliah',
              style: FontTheme.poppins14w500black().copyWith(
                color: BaseColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// `Wajib Fakultas`, `4 SKS`, `Sem 4`. The type is dropped when the course
  /// endpoint has none.
  Widget _buildCoursePills(CalculatorComponentState data) {
    final courseType = data.courseType;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (courseType != null && courseType.isNotEmpty) InfoPill(courseType),
        InfoPill('${widget.courseSKS} SKS'),
        InfoPill('Sem ${semesterShortLabel(widget.givenSemester)}'),
      ],
    );
  }

  Widget _buildEmptyComponents() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Belum Ada Komponen',
          style: FontTheme.poppins12w500black().copyWith(
            color: BaseColors.gray3,
          ),
        ),
      ),
    );
  }

  Widget _buildAddComponentButton() {
    return GestureDetector(
      onTap: _addComponent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: BaseColors.purpleHearth),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Tambah Komponen',
            style: FontTheme.poppins14w600black().copyWith(
              color: BaseColors.purpleHearth,
            ),
          ),
        ),
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
          'Gagal memuat komponen nilai.\nTarik ke bawah untuk mencoba lagi.',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _changeTarget(GradeTarget target) {
    calculatorComponentRM.setState(
      (s) => s.changeTarget(target, widget.calculatorId),
    );
  }

  /// Both flows open over the page rather than pushing a route, so on save we
  /// just refetch instead of rebuilding this page with a locally guessed
  /// total.
  Future<void> _addComponent() async {
    final result = await KomponenBottomSheet.showAdd(
      context,
      calculatorId: widget.calculatorId,
    );

    if (result == null) {
      return;
    }

    await retrieveData();
    if (mounted) {
      _showBanner(result);
    }
  }

  Future<void> _editComponent(ComponentBreakdown breakdown) async {
    final result = await KomponenBottomSheet.showEdit(
      context,
      id: breakdown.id,
      componentName: breakdown.name,
      componentWeight: breakdown.weight,
    );

    if (result == null) {
      return;
    }

    if (result.action == KomponenSheetAction.deleted) {
      // Runs here, not in the sheet: deleteComponent raises a Flushbar, and a
      // Flushbar is a route. Raised while the sheet was still open it would
      // sit on top of it, and the sheet's own pop would take the toast
      // instead — leaving the navigator to assert when the toast expired.
      await _deleteComponent(breakdown);
    } else {
      await retrieveData();
    }

    if (mounted) {
      _showBanner(result);
    }
  }

  Future<void> _deleteComponent(ComponentBreakdown breakdown) async {
    await componentRM.setState((s) => s.componentChange = true);
    await componentRM.setState(
      (s) => s.deleteComponent(QueryComponent(id: breakdown.id)),
    );
    await retrieveData();
  }

  Future<void> _deleteCourse() async {
    await showDialog(
      context: context,
      builder: (context) => DeleteDialog(
        title: 'Hapus Matkul',
        content: 'Apakah kamu yakin ingin menghapus '
            'Kalkulator ${widget.courseName}?',
        onConfirm: () async {
          nav
            ..pop()
            ..pop();
          await calculatorRM.setState(
            (s) => s.deleteCalculator(
              query: QueryCalculator(courseId: widget.courseId),
              givenSemester: widget.givenSemester,
              courseName: widget.courseName,
              totalScore: widget.totalScore,
            ),
          );
        },
      ),
    );
  }
}
