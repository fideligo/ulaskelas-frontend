// Created by Muhamad Fauzi Ridwan on 07/11/21.

part of '_pages.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({
    super.key,
  });

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends BaseStateful<FilterPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void init() {
    filterRM.state.initTempState();
    filterRM.state.fetchMajors();
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: BaseColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: BaseColors.mineShaft),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter',
            style: FontTheme.poppins14w700black().copyWith(
              fontSize: 16,
            ),
          ),
          const HeightSpace(2),
          Text(
            'Pilih filter mata kuliah',
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
  Widget buildNarrowLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return OnReactive(
      () {
        return Stack(
          children: [
            Positioned.fromRelativeRect(
              rect: const RelativeRect.fromLTRB(0, 0, 0, 40),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: BaseColors.purpleHearth,
                      ),
                  textTheme: Theme.of(context).textTheme.copyWith(
                        bodySmall: FontTheme.poppins14w700black().copyWith(
                          fontSize: 13,
                        ),
                      ),
                  checkboxTheme: CheckboxThemeData(
                    checkColor: MaterialStateProperty.all(Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    side: const BorderSide(
                      color: BaseColors.purpleHearth,
                      width: 2,
                    ),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  children: [
                    Text(
                      'Jurusan',
                      style: FontTheme.poppins14w700black().copyWith(
                        color: BaseColors.purpleHearth, // Purple title
                      ),
                    ),
                    const HeightSpace(8),
                    if (filterRM.state.isLoadingMajors)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: BaseColors.purpleHearth,
                            ),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField2<String?>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                            left: 3,
                            right: 16,
                            top: 12,
                            bottom: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: BaseColors.gray2, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: BaseColors.gray2, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: BaseColors.gray2, width: 2),
                          ),
                          filled: true,
                          fillColor: BaseColors.white,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 250,
                          elevation: 0,
                          offset: const Offset(0, -8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: BaseColors.gray2, width: 2),
                            color: BaseColors.white,
                          ),
                          scrollbarTheme: ScrollbarThemeData(
                            radius: const Radius.circular(40),
                            thickness: MaterialStateProperty.all(6),
                            thumbVisibility: MaterialStateProperty.all(true),
                            thumbColor:
                                MaterialStateProperty.all(BaseColors.gray2),
                            crossAxisMargin: 8,
                            mainAxisMargin: 8,
                          ),
                        ),
                        hint: Text(
                          'Pilih Jurusan',
                          style: FontTheme.poppins12w400black().copyWith(
                            color: BaseColors.gray2,
                            fontSize: 16,
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: BaseColors.purpleHearth,
                          ),
                          openMenuIcon: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: BaseColors.purpleHearth,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        dropdownSearchData: DropdownSearchData(
                          searchController: _searchController,
                          searchInnerWidgetHeight: 52,
                          searchInnerWidget: Padding(
                            padding: const EdgeInsets.only(
                              top: 12,
                              bottom: 8,
                              right: 12,
                              left: 12,
                            ),
                            child: SizedBox(
                              height: 36,
                              child: TextFormField(
                                controller: _searchController,
                                style: FontTheme.poppins12w400black(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  hintText: 'Search',
                                  hintStyle:
                                      FontTheme.poppins12w400black().copyWith(
                                    color: BaseColors.gray2,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.search,
                                    color: BaseColors.gray2,
                                    size: 18,
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                    minHeight: 36,
                                    minWidth: 36,
                                  ),
                                  filled: true,
                                  fillColor: BaseColors.gray4,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          searchMatchFn: (item, searchValue) {
                            final displayName = filterRM.state
                                .getMajorDisplayName(item.value ?? '');
                            return displayName
                                .toLowerCase()
                                .contains(searchValue.toLowerCase());
                          },
                        ),
                        onMenuStateChange: (isOpen) {
                          if (!isOpen) {
                            _searchController.clear();
                          }
                        },
                        value: filterRM.state.tempSelectedJurusan,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              '-- Semua Jurusan --',
                              style: FontTheme.poppins12w400black().copyWith(
                                color: BaseColors.gray2,
                              ),
                            ),
                          ),
                          ...filterRM.state.majorOrgCodes.map((orgCode) {
                            return DropdownMenuItem<String?>(
                              value: orgCode,
                              child: Text(
                                filterRM.state.getMajorDisplayName(orgCode),
                                style: FontTheme.poppins12w400black(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            filterRM.state.tempSelectedJurusan = newValue;
                          });
                        },
                      ),
                    const HeightSpace(20),
                    Text(
                      'Jenis Mata Kuliah',
                      style: FontTheme.poppins14w700black(),
                    ),
                    const HeightSpace(8),
                    GridView.count(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 5,
                      children: filterRM.state.matkulTypes.map((item) {
                        return CheckboxTile(
                          value:
                              filterRM.state.tempSelectedType.contains(item.value),
                          text: item.text,
                          onChanged: (val) {
                            if (val ?? true) {
                              filterRM.setState(
                                (s) => s.pickMatkulType(item.value.toString()),
                              );
                            } else {
                              filterRM.setState(
                                (s) =>
                                    s.discardMatkulType(item.value.toString()),
                              );
                            }
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const HeightSpace(20),
                    Text(
                      'Jumlah SKS',
                      style: FontTheme.poppins14w700black(),
                    ),
                    const HeightSpace(8),
                    GridView.count(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 5,
                      children: filterRM.state.sksTotals.map((item) {
                        return CheckboxTile(
                          value:
                              filterRM.state.tempSelectedSks.contains(item.value),
                          text: item.text,
                          onChanged: (val) {
                            if (val ?? true) {
                              filterRM.setState(
                                (s) => s.pickSksTotal(item.value.toString()),
                              );
                            } else {
                              filterRM.setState(
                                (s) => s.discardSksTotal(item.value.toString()),
                              );
                            }
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const HeightSpace(20),
                    Text(
                      'Semester Wajib Mengambil',
                      style: FontTheme.poppins14w700black(),
                    ),
                    const HeightSpace(8),
                    GridView.count(
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 5,
                      children:
                          filterRM.state.semesterPreconditions.map((item) {
                        return CheckboxTile(
                          value: filterRM.state.tempSelectedSemester
                              .contains(item.value),
                          text: item.text,
                          onChanged: (val) {
                            if (val ?? true) {
                              filterRM.setState(
                                (s) => s.pickSemesterPrecondition(
                                  item.value.toString(),
                                ),
                              );
                            } else {
                              filterRM.setState(
                                (s) => s.discardSemesterPrecondition(
                                  item.value.toString(),
                                ),
                              );
                            }
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: BaseColors.white,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        BaseColors.purpleHearth, // Purple background
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    filterRM.state.applyFilters();
                    filterRM.notify();
                    nav.pop<bool>(true);
                    MixpanelService.track(
                      'apply_course_filter',
                      params: {
                        'jenis_matkul': filterRM.state.selectedType.toString(),
                        'jumlah_sks': filterRM.state.selectedSks.toString(),
                        'semester_wajib_ambil':
                            filterRM.state.selectedSemester.toString(),
                        'jurusan': filterRM.state.selectedJurusan ?? '',
                      },
                    );
                  },
                  child: Center(
                    child: Text(
                      'Terapkan Filter',
                      style: FontTheme.poppins14w700black().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
}
