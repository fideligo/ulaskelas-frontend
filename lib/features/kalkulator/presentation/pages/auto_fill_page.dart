part of '_pages.dart';

/// Reviews the courses SLCM reports for a semester before they are imported.
///
/// Opened with the SSO credentials the student just entered; the backend uses
/// them once to sign in to SLCM and never returns them.
///
/// The semester is whatever the session reports: either the optional override
/// typed into the credential sheet, or the one the backend derived from the
/// student's NPM. Every label here reads `AutoFillState.givenSemester` once
/// the create call answers.
///
/// `preview.matched` is what gets imported and each row can be dropped from
/// the list; `preview.duplicates` is already in the semester and
/// `preview.unmatched` has no local course to import into, so both are shown
/// inert.
///
/// Dropping a row is local for now: the confirm call takes no body and the
/// backend imports the whole preview regardless. `AutoFillState` tracks the
/// removals in `excludedCourseCodes`, ready to send once the endpoint accepts
/// them.
class AutoFillPage extends StatefulWidget {
  const AutoFillPage({required this.credentials, super.key});

  /// Used exactly once, to open the session in `init`. Held by the widget
  /// rather than any longer-lived object so it dies with the route.
  final SlcmCredentials credentials;

  @override
  _AutoFillPageState createState() => _AutoFillPageState();
}

class _AutoFillPageState extends BaseStateful<AutoFillPage> {
  final _userGeneration =
      int.tryParse(profileRM.state.profile.generation ?? '') ?? 0;

  @override
  void init() {
    autoFillRM.setState((s) => s.retrieveData(widget.credentials));
  }

  @override
  void dispose() {
    // Stops the poll timer and releases the session. The backend allows one
    // live session per user, so leaving on an unfinished one would lock the
    // student out of their next attempt until it times out server-side.
    unawaited(autoFillRM.state.cancel());
    super.dispose();
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute(
      bottomNavigation: _buildContinueButton(),
    );
  }

  /// The semester the backend picked, e.g. `Semester 9`.
  ///
  /// Falls back to a semester-less title for the stretch before the create
  /// call answers, which is the only time the page does not know it yet.
  String get _semesterLabel {
    final givenSemester = autoFillRM.state.givenSemester;
    if (givenSemester == null || givenSemester.isEmpty) {
      return 'Isi Otomatis';
    }
    return semesterFullLabel(givenSemester);
  }

  /// Wrapped in an `OnBuilder` because the scaffold builds its app bar outside
  /// the body's, so the title would otherwise keep the placeholder it was
  /// given before the session reported which semester this is.
  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: OnBuilder(
        listenTo: autoFillRM,
        builder: () => BaseAppBar(
          label: _semesterLabel,
          centerTitle: false,
          elevation: 0,
          style: FontTheme.poppins18w700black(),
        ),
      ),
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
        if (data.hasStaleDataWarning) ...[
          _buildStaleDataBanner(),
          const HeightSpace(16),
        ],
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
                'Matkul ${semesterFullLabel(data.givenSemester ?? '')}',
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
        ..._buildUnmatchedSection(data),
      ],
    );
  }

  /// Advisory shown when the backend could not confirm SLCM served the current
  /// term.
  ///
  /// Deliberately not a blocker: the rows may still be exactly right, and the
  /// student is the one who knows whether their IRS changed recently. The
  /// continue button is untouched by this.
  Widget _buildStaleDataBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BaseColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BaseColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: BaseColors.mineShaft,
          ),
          const WidthSpace(10),
          Expanded(
            child: Text(
              'Data dari SLCM mungkin belum yang terbaru, tetapi Anda tetap '
              'dapat melanjutkan import.',
              style: FontTheme.poppins12w400black(),
            ),
          ),
        ],
      ),
    );
  }

  /// Rows SLCM reported that no local course matched.
  ///
  /// Shown so a student who expected eight courses and sees six knows why,
  /// rather than assuming the import lost them. Nothing can be done about
  /// these from here - there is no catalog entry to attach a calculator row
  /// to - so they carry no control at all.
  List<Widget> _buildUnmatchedSection(AutoFillState data) {
    final unmatched = data.unmatchedCourses;
    if (unmatched.isEmpty) {
      return [];
    }
    return [
      const HeightSpace(10),
      Text(
        'Tidak ditemukan di katalog (${unmatched.length})',
        style: FontTheme.poppins14w700black().copyWith(
          color: BaseColors.gray2,
        ),
      ),
      const HeightSpace(4),
      Text(
        'Matkul ini ada di IRS kamu tapi belum terdaftar di Teman Kuliah, '
        'jadi tidak bisa ditambahkan.',
        style: FontTheme.poppins12w400black().copyWith(
          color: BaseColors.gray2,
        ),
      ),
      const HeightSpace(14),
      ...unmatched.map(
        (course) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CourseChecklistCard(
            name: course.name,
            // The scraped shape spells the credit count `credits` where a
            // resolved course says `sks`.
            sks: course.credits,
            code: course.code,
            isSelected: false,
            isDisabled: true,
          ),
        ),
      ),
    ];
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
                  academicTermLabel(data.givenSemester ?? '', _userGeneration),
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
      case SlcmSessionStatus.authenticating:
        return 'Menghubungkan ke SSO UI...';
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
      // Carried as the fallback only; on this branch the review page reads the
      // live value off `AutoFillState` so the two cannot drift.
      givenSemester: autoFillRM.state.givenSemester ?? '',
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
