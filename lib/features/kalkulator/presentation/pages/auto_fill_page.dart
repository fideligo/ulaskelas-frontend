part of '_pages.dart';

/// Reviews the courses SLCM reports for a semester before they are imported.
///
/// `preview.matched` is what gets imported and each row can be dropped from
/// the list; `preview.duplicates` is already in the semester, so it is shown
/// greyed out with no control on it at all.
///
/// Dropping a row is local for now: the confirm call takes no body and the
/// backend imports the whole preview regardless. `AutoFillState` tracks the
/// removals in `excludedCourseCodes`, ready to send once the endpoint accepts
/// them.
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
        onIdle: _buildWaiting,
        onWaiting: _buildWaiting,
        onError: (dynamic error, refresh) => _buildError(error),
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
        if (data.selectedCourses.isEmpty)
          _buildEmptyMatched()
        else
          ...data.selectedCourses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseChecklistCard(
                name: course.name,
                sks: course.sks,
                type: course.type,
                code: course.code,
                facultyName: course.facultyName,
                // Ticked with no `onTap`: a row is either on the list or off
                // it, and the trash button is the only way off.
                isSelected: true,
                onDelete: () => autoFillRM.state.remove(course),
              ),
            ),
          ),
        ..._buildDuplicateSection(data),
      ],
    );
  }

  /// Reachable by removing every row, so it explains the way back rather than
  /// leaving a gap under the heading.
  Widget _buildEmptyMatched() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Semua matkul sudah dihapus dari daftar. Kembali dan ulangi '
        'pengambilan data jika ingin menambahkannya lagi.',
        style: FontTheme.poppins12w400black().copyWith(
          color: BaseColors.gray2,
        ),
      ),
    );
  }

  /// Courses SLCM found that are already in this semester.
  ///
  /// Listed so the student can see nothing was silently dropped, and drawn
  /// inert because the import skips them either way — there is no removal to
  /// offer on a row that was never going to be written.
  List<Widget> _buildDuplicateSection(AutoFillState data) {
    final duplicates = data.duplicateCourses;
    if (duplicates.isEmpty) {
      return [];
    }
    return [
      const HeightSpace(10),
      Text(
        'Sudah ada di semester ini (${duplicates.length})',
        style: FontTheme.poppins14w700black().copyWith(
          color: BaseColors.gray2,
        ),
      ),
      const HeightSpace(4),
      Text(
        'Matkul ini tidak akan ditambahkan lagi.',
        style: FontTheme.poppins12w400black().copyWith(
          color: BaseColors.gray2,
        ),
      ),
      const HeightSpace(14),
      ...duplicates.map(
        (course) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CourseChecklistCard(
            name: course.name,
            sks: course.sks,
            type: course.type,
            code: course.code,
            facultyName: course.facultyName,
            isSelected: false,
            isDisabled: true,
          ),
        ),
      ),
    ];
  }

  /// Reports what SLCM matched, before any removal. The `dipilih` count
  /// beside the list falls below this as rows are dropped.
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
              // Guards the empty case: SLCM matched nothing, or the student
              // removed every row, so there is nothing to review.
              onTap: hasSelection ? _goToReview : null,
            ),
          ),
        );
      },
    );
  }

  /// Held for as long as the student takes to log into SLCM, so it says which
  /// half of the wait we are in rather than spinning mutely.
  ///
  /// Reads the status straight off the state: `AutoFillState._apply` calls
  /// `autoFillRM.notify()` on every poll, which rebuilds this without leaving
  /// the waiting branch.
  Widget _buildWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: BaseColors.purpleHearth,
              ),
            ),
            const HeightSpace(16),
            Text(
              _waitingLabel,
              style: FontTheme.poppins14w400black().copyWith(
                color: BaseColors.gray2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String get _waitingLabel {
    switch (autoFillRM.state.status) {
      case SlcmSessionStatus.waitingLogin:
        return 'Menunggu Anda login di browser...';
      case SlcmSessionStatus.scraping:
        return 'Sedang mengambil data dari SLCM...';
      // Reached only in the gap before the session exists, and briefly at
      // `ready` before the waiting branch hands over to the list.
      case SlcmSessionStatus.ready:
      case SlcmSessionStatus.imported:
      case SlcmSessionStatus.failed:
      case SlcmSessionStatus.expired:
      case SlcmSessionStatus.cancelled:
      case SlcmSessionStatus.unknown:
        return 'Memproses...';
    }
  }

  /// Shows the reason the session ended when there is one — an expiry, a
  /// scraper failure, or the student cancelling the login — and falls back to
  /// the generic line otherwise.
  Widget _buildError(dynamic error) {
    final message = error is Failure ? error.message : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message?.isNotEmpty ?? false
              ? message!
              : 'Gagal mengambil data dari SLCM.',
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
      // Puts the review step on the SLCM branch: it confirms the session
      // server-side instead of posting the course list itself.
      slcmSessionId: autoFillRM.state.sessionId,
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
