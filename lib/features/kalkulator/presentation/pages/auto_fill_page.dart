part of '_pages.dart';

/// Reviews the courses SIAK reports for a semester before they are imported.
class AutoFillPage extends StatefulWidget {
  const AutoFillPage({
    required this.givenSemester,
    super.key,
  });

  final String givenSemester;

  @override
  _AutoFillPageState createState() => _AutoFillPageState();
}

class _AutoFillPageState extends BaseStateful<AutoFillPage> {
  final _userGeneration =
      int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;

  @override
  void init() {
    autoFillRM.setState((s) => s.retrieveData(widget.givenSemester));
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute(
      bottomNavigation: _buildContinueButton(),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return BaseAppBar(
      label: semesterFullLabel(widget.givenSemester),
      centerTitle: false,
      elevation: 0,
      style: FontTheme.poppins18w700black(),
    );
  }

  @override
  Widget buildNarrowLayout(BuildContext context, SizingInformation sizeInfo) {
    return SafeArea(
      child: OnBuilder<AutoFillState>.all(
        listenTo: autoFillRM,
        onIdle: WaitingView.new,
        onWaiting: WaitingView.new,
        onError: (dynamic error, refresh) => _buildError(),
        onData: _buildCourseList,
      ),
    );
  }

  @override
  Widget buildWideLayout(BuildContext context, SizingInformation sizeInfo) {
    return buildNarrowLayout(context, sizeInfo);
  }

  @override
  Future<bool> onBackPressed() async {
    return true;
  }

  Widget _buildCourseList(AutoFillState data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'Pilih mata kuliah semester ini',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
        ),
        const HeightSpace(18),
        _buildSummaryCard(data),
        const HeightSpace(22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Matkul ${semesterFullLabel(widget.givenSemester)}',
                style: FontTheme.poppins14w700black(),
              ),
            ),
            const WidthSpace(12),
            Text(
              '${data.selectedCount} dipilih',
              style: FontTheme.poppins14w700black().copyWith(
                color: BaseColors.purpleHearth,
              ),
            ),
          ],
        ),
        const HeightSpace(14),
        ...data.courses.map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CourseChecklistCard(
              name: course.name,
              sks: course.sks,
              type: course.type,
              code: course.code,
              isSelected: data.isSelected(course),
              onTap: () => autoFillRM.state.toggle(course),
            ),
          ),
        ),
      ],
    );
  }

  /// Reports what SIAK found. The count stays put when rows are unchecked —
  /// it describes the import, not the current selection.
  Widget _buildSummaryCard(AutoFillState data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF44309F), Color(0xFF5C48D6)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: BaseColors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 22,
                color: BaseColors.purpleHearth,
              ),
            ),
          ),
          const WidthSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.totalFound} Matkul ditemukan dari SIAK',
                  style: FontTheme.poppins16w700white(),
                ),
                const HeightSpace(6),
                Text(
                  academicTermLabel(widget.givenSemester, _userGeneration),
                  style: FontTheme.poppins12w400black().copyWith(
                    color: BaseColors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  'Uncheck jika ada yang di-drop',
                  style: FontTheme.poppins12w400black().copyWith(
                    color: BaseColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return OnBuilder(
      listenTo: autoFillRM,
      builder: () {
        final hasSelection = autoFillRM.state.selectedCount > 0;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: AutoLayoutButton(
              text: 'Lanjut Review',
              backgroundColor: BaseColors.purpleHearth,
              textStyle: FontTheme.poppins14w700white(),
              // Nothing to review when every course has been unchecked.
              onTap: hasSelection ? _goToReview : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Gagal mengambil data dari SIAK.',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _goToReview() {
    nav.goToConfirmSemesterPage(
      givenSemester: widget.givenSemester,
      courses: autoFillRM.state.selectedCourses
          .map((c) => CourseModel(
                code: c.code,
                name: c.name,
                sks: c.sks,
                codeDesc: c.type,
              ))
          .toList(),
    );
  }
}
