part of '_pages.dart';

/// Searches the course catalogue so a semester can be filled in by hand.
class ManualFillPage extends StatefulWidget {
  const ManualFillPage({
    required this.givenSemester,
    super.key,
  });

  final String givenSemester;

  @override
  _ManualFillPageState createState() => _ManualFillPageState();
}

class _ManualFillPageState extends BaseStateful<ManualFillPage> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void init() {
    manualFillRM.state.reset();
    _scrollController.addListener(_onScroll);
    manualFillRM.setState((s) => s.retrieveData(QuerySearchCourse()));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih mata kuliah semester ini',
                  style: FontTheme.poppins12w400black().copyWith(
                    color: BaseColors.gray2,
                  ),
                ),
                const HeightSpace(16),
                _buildSearchRow(),
                OnBuilder(
                  listenTo: manualFillRM,
                  builder: _buildSelectedPills,
                ),
                const HeightSpace(18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hasil Pencarian',
                        style: FontTheme.poppins14w700black(),
                      ),
                    ),
                    const WidthSpace(12),
                    OnBuilder(
                      listenTo: manualFillRM,
                      builder: () => Text(
                        '${manualFillRM.state.selectedCount} Terpilih',
                        style: FontTheme.poppins14w700black().copyWith(
                          color: BaseColors.purpleHearth,
                        ),
                      ),
                    ),
                  ],
                ),
                const HeightSpace(12),
              ],
            ),
          ),
          Expanded(
            child: OnBuilder<ManualFillState>.all(
              listenTo: manualFillRM,
              onIdle: _buildSkeleton,
              onWaiting: _buildSkeleton,
              onError: (dynamic error, refresh) => _buildError(),
              onData: _buildResults,
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
    return true;
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: OnBuilder(
            listenTo: manualFillRM,
            builder: () => CustomSearchField(
              controller: manualFillRM.state.controller,
              focusNode: _focusNode,
              hintText: 'Cari mata kuliah...',
              onQueryChanged: manualFillRM.state.onQueryChanged,
              onClear: () {
                _focusNode.unfocus();
                manualFillRM.state.controller.clear();
                manualFillRM.state.onQueryChanged('');
              },
            ),
          ),
        ),
        const WidthSpace(12),
        InkWell(
          onTap: _openFilter,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.filter_alt,
              size: 30,
              color: BaseColors.purpleHearth,
            ),
          ),
        ),
      ],
    );
  }

  /// One pill per selected course, so a pick made under an earlier search
  /// stays visible after the results change underneath it.
  Widget _buildSelectedPills() {
    final selected = manualFillRM.state.selectedCourses;
    if (selected.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: selected
              .map(
                (course) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SelectedCoursePill(
                    label: course.shortName ?? course.name ?? '-',
                    onRemove: () => manualFillRM.state.unselect(course),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildResults(ManualFillState data) {
    if (data.courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Mata kuliah tidak ditemukan.',
            style: FontTheme.poppins12w400black().copyWith(
              color: BaseColors.gray2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      // One extra row carries the pagination spinner.
      itemCount: data.courses.length + 1,
      separatorBuilder: (context, index) => const HeightSpace(12),
      itemBuilder: (context, index) {
        if (index == data.courses.length) {
          return _buildPaginationFooter(data);
        }

        final course = data.courses[index];
        return CourseChecklistCard(
          name: course.name,
          sks: course.sks,
          type: course.codeDesc,
          code: course.code,
          isSelected: data.isSelected(course),
          onTap: () => manualFillRM.state.toggle(course),
        );
      },
    );
  }

  Widget _buildPaginationFooter(ManualFillState data) {
    if (!data.isLoadingMore) {
      return const SizedBox(height: 8);
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: BaseColors.purpleHearth,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: 6,
      separatorBuilder: (context, index) => const HeightSpace(12),
      itemBuilder: (context, index) => const SkeletonCourseSearch(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Gagal memuat daftar mata kuliah.',
          style: FontTheme.poppins12w400black().copyWith(
            color: BaseColors.gray2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return OnBuilder(
      listenTo: manualFillRM,
      builder: () {
        final hasSelection = manualFillRM.state.selectedCount > 0;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: AutoLayoutButton(
              text: 'Lanjut Review',
              backgroundColor: BaseColors.purpleHearth,
              textStyle: FontTheme.poppins14w700white(),
              onTap: hasSelection ? _goToReview : null,
            ),
          ),
        );
      },
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset < maxScroll * 0.9) {
      return;
    }
    // Read straight off the state: notify() alone must not restart the list.
    manualFillRM.state.retrieveMoreData(
      QuerySearchCourse(name: manualFillRM.state.controller.text),
    );
  }

  void _openFilter() {
    WarningMessenger('Filter belum tersedia').show(context);
  }

  void _goToReview() {
    nav.goToConfirmSemesterPage(
      givenSemester: widget.givenSemester,
      courses: manualFillRM.state.selectedCourses
          .map(SiakCourseModel.fromCourse)
          .toList(),
    );
  }
}
