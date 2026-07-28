part of '_pages.dart';

class SearchCourseCalculator extends StatefulWidget {
  const SearchCourseCalculator({
    required this.givenSemester,
    super.key,
  });

  final String givenSemester;

  @override
  _SearchCourseCalculatorState createState() => _SearchCourseCalculatorState();
}

class _SearchCourseCalculatorState
    extends BasePaginationState<SearchCourseCalculator, SearchCourseState> {
  final focusNode = FocusNode();

  Timer? _debounce;

  @override
  void init() {
    focusNode.addListener(() {
      final controller = searchCourseRM.state.controller;
      if (controller.text.isNotEmpty && !focusNode.hasFocus) {
        searchCourseRM.setState((s) => s.addToHistory(controller.text));
      }
    });
    searchCourseRM.state.controller.clear();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    filterRM.setState((s) => s.reset());
    super.dispose();
  }

  @override
  Future<void> retrieveData() async {
    await searchCourseRM.setState(
      (s) => s.retrieveData(
        QuerySearchCourse(
          name: searchCourseRM.state.controller.text,
        ),
      ),
    );
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BaseColors.mineShaft),
        onPressed: () async {
          await onBackPressed();
          nav.pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semester ${widget.givenSemester}',
            style: FontTheme.poppins14w700black().copyWith(
              fontSize: 16,
            ),
          ),
          const HeightSpace(2),
          Text(
            'Pilih mata kuliah semester ini',
            style: FontTheme.poppins12w400black().copyWith(
              color: BaseColors.gray2,
            ),
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  @override
  Widget buildNarrowLayout(
    BuildContext context,
    ReactiveModel<SearchCourseState> k,
    SizingInformation sizeInfo,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OnReactive(
                      () => SearchField(
                        hintText: 'Cari mata kuliah...',
                        focusNode: focusNode,
                        controller: searchCourseRM.state.controller,
                        onClear: () {
                          focusNode.unfocus();
                          searchCourseRM.state.controller.clear();
                          onQueryChanged('');
                          searchCourseRM.notify();
                        },
                        onFieldSubmitted: (val) {
                          searchCourseRM.state.addToHistory(val);
                        },
                        onChange: onQueryChanged,
                      ),
                    ),
                  ),
                  const WidthSpace(16),
                  IconButton(
                    onPressed: () async {
                      final hasFilter = await nav.push<bool>(const FilterPage());
                      if (hasFilter ?? false) {
                        // Apply filter logic
                        onQueryChanged(searchCourseRM.state.controller.text, force: true);
                      }
                    },
                    icon: const Icon(
                      Icons.filter_alt,
                      color: Color(0xFF4921B8),
                    ),
                  ),
                ],
              ),
              const HeightSpace(16),
              // Selected Matkul Pills
              OnReactive(() {
                final selectedCourses = searchCourseRM.state.selectedCourses;
                if (selectedCourses.isEmpty) return const SizedBox.shrink();
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: selectedCourses.map((course) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF4921B8)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              course.shortName ?? course.name ?? '-',
                              style: FontTheme.poppins12w600black().copyWith(
                                color: const Color(0xFF4921B8),
                              ),
                            ),
                            const WidthSpace(8),
                            InkWell(
                              onTap: () {
                                searchCourseRM.state.removeCourse(course);
                              },
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF4921B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
        
        // Hasil Pencarian Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hasil Pencarian',
                style: FontTheme.poppins16w700black().copyWith(
                  fontSize: 18,
                ),
              ),
              OnReactive(() {
                final selectedCount = searchCourseRM.state.selectedCourses.length;
                return Text(
                  '$selectedCount Terpilih',
                  style: FontTheme.poppins14w700black().copyWith(
                    color: const Color(0xFF4921B8),
                  ),
                );
              }),
            ],
          ),
        ),

        Expanded(
          child: OnReactive(
            () {
              if (focusNode.hasFocus &&
                  searchCourseRM.state.controller.text.isEmpty) {
                return _buildHistory();
              } else {
                return SearchListViewSimplified(
                  refreshIndicatorKey: refreshIndicatorKey,
                  scrollController: scrollController,
                  onScroll: onScroll,
                  onRefresh: retrieveData,
                );
              }
            },
          ),
        ),
        Container(
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF4921B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (searchCourseRM.state.selectedCourses.isEmpty) {
                ErrorMessenger('Pilih minimal satu mata kuliah').show(context);
                return;
              }
              final selectedCourses =
                  List<CourseModel>.from(searchCourseRM.state.selectedCourses);
              
              nav.push(
                KonfirmasiSemesterPage(
                  givenSemester: widget.givenSemester,
                  selectedCourses: selectedCourses,
                ),
              );
            },
            child: Text(
              'Lanjut Review',
              style: FontTheme.poppins14w700black().copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildWideLayout(
    BuildContext context,
    ReactiveModel<SearchCourseState> k,
    SizingInformation sizeInfo,
  ) {
    return buildNarrowLayout(context, k, sizeInfo);
  }

  @override
  Future<bool> onBackPressed() async {
    focusNode.unfocus();
    await searchCourseRM.setState((s) => s.selectedCourses.clear());
    return true;
  }

  @override
  void onScroll() {
    completer?.complete();
    final query = QuerySearchCourse(
      name: searchCourseRM.state.controller.text,
    );
    searchCourseRM.state.retrieveMoreData(query).then((value) {
      completer = Completer<void>();
      searchCourseRM.notify();
    }).onError((error, stackTrace) {
      completer = Completer<void>();
    });
  }

  @override
  bool scrollCondition() {
    return !searchCourseRM.state.hasReachedMax;
  }

  /// Every Query changed do debouncing and rebuild.
  Future<void> onQueryChanged(String val, {bool force = false}) async {
    if (val == searchCourseRM.state.lastQuery && !force) {
      return;
    }
    searchCourseRM.state.lastQuery = val;
    searchCourseRM.notify();

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    await searchCourseRM.setState((s) {
      s.hasReachedMax = false;
      return;
    });
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      final query = QuerySearchCourse(name: val);
      // final query = QuerySearchCourse();
      searchCourseRM.setState((s) {
        return searchCourseRM.state.searchMatkul(query).then(
              (value) => searchCourseRM.state.retrieveMoreData(query).then(
                    (value) => searchCourseRM.notify(),
                  ),
            );
      });
    });
  }

  Widget _buildHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Riwayat Pencarian',
                  style: FontTheme.poppins14w700black(),
                ),
                InkWell(
                  onTap: () {
                    searchCourseRM.setState((s) => s.clearHistory());
                  },
                  child: Text(
                    'Hapus',
                    style: FontTheme.poppins12w500black().copyWith(
                      color: BaseColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const HeightSpace(10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: searchCourseRM.state.history.map((element) {
              return InkWell(
                onTap: () {
                  final controller = searchCourseRM.state.controller;
                  focusNode.requestFocus();
                  controller
                    ..text = element
                    ..selection = TextSelection.fromPosition(
                      TextPosition(
                        offset: searchCourseRM.state.controller.text.length,
                      ),
                    );
                  onQueryChanged(element);
                },
                child: Tag(
                  label: element,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool enable = true;
}
