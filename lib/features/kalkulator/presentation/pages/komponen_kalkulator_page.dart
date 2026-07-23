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
  @override
  void init() {
    retrieveData();
    calculatorComponentRM.state.loadCourseType(widget.courseId);
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
    return SafeArea(
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
        if (data.hasFullWeight)
          CardTargetGrade(
            target: data.target,
            currentGrade: data.currentGrade,
            currentScore: data.currentScore,
            onTargetSelected: _changeTarget,
          )
        else
          _buildWeightWarning(),
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

  Widget _buildWeightWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: BaseColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: BoxShadowDecorator().defaultShadow(context),
      ),
      child: Row(
        children: [
          Image.asset('assets/ruby/ruby_sad.png', height: 42),
          const WidthSpace(12),
          Expanded(
            child: Text(
              'Total bobot belum 100%. '
              'Lengkapi dulu agar Ruby bisa memberi rekomendasi.',
              style: FontTheme.poppins12w500black(),
            ),
          ),
        ],
      ),
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
    final changed = await KomponenBottomSheet.showAdd(
      context,
      calculatorId: widget.calculatorId,
    );

    if (changed ?? false) {
      await retrieveData();
    }
  }

  Future<void> _editComponent(ComponentBreakdown breakdown) async {
    final changed = await KomponenBottomSheet.showEdit(
      context,
      id: breakdown.id,
      componentName: breakdown.name,
      componentWeight: breakdown.weight,
    );

    if (changed ?? false) {
      await retrieveData();
    }
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
