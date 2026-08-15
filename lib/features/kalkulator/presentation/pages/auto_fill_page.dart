part of '_pages.dart';

/// Reviews the courses SLCM reports for a semester before they are imported.
///
/// The list is read-only. The backend's confirm call imports everything in
/// `preview.matched` and ignores any body, so offering a checkbox here would
/// promise a choice the API cannot honour.
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
  void dispose() {
    // Stops the poll timer and hands the shared SLCM browser back. The backend
    // allows one live session at a time, so leaving on an unfinished session
    // would lock the student out of their next attempt until it times out.
    unawaited(autoFillRM.state.cancel());
    super.dispose();
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
              facultyName: course.facultyName,
              // Locked on, and no `onTap` — the confirm endpoint imports every
              // matched course and accepts no selection, so a togglable box
              // would let the student uncheck a row that is imported anyway.
              isSelected: true,
            ),
          ),
        ),
      ],
    );
  }

  /// Reports what SLCM found. Every row is imported, so this count and the
  /// `dipilih` count beside the list always agree.
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
                  '${data.totalFound} Matkul ditemukan dari SLCM',
                  style: FontTheme.poppins16w700white(),
                ),
                const HeightSpace(6),
                Text(
                  academicTermLabel(widget.givenSemester, _userGeneration),
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
              // Selection is locked on, so this only guards the empty case:
              // SLCM matched nothing, and there is nothing to import.
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
          'Gagal mengambil data dari SLCM.',
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
          .map(
            (c) => CourseModel(
              // The import posts ids; dropping it here makes the confirm step
              // throw on `e.id!`.
              id: c.id,
              code: c.code,
              name: c.name,
              sks: c.sks,
              codeDesc: c.type,
              faculties: c.faculties,
            ),
          )
          .toList(),
    );
  }
}
