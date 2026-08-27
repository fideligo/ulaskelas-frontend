import 'package:ulaskelas/core/bases/states/_states.dart';
import 'package:ulaskelas/features/matkul/search/domain/entities/_entities.dart';

class QuerySearchCourse extends QuerySearch {
  QuerySearchCourse({
    this.isShowAll = true,
    String name = '',
    int page = 1,
  }) : super(
          q: name,
          page: page,
        );

  bool isShowAll;

  @override
  String toString() {
    final data = <String, String>{};
    data['show_all'] = isShowAll.toString();
    if (page != null) {
      data['page'] = page.toString();
    }
    if (q.isNotEmpty) {
      data['name'] = q;
    }
    if (filterRM.state.selectedSks.isNotEmpty) {
      data['sks'] = filterRM.state.selectedSks.join(',');
    }
    if (filterRM.state.selectedSemester.isNotEmpty) {
      data['term'] = filterRM.state.selectedSemester.join(',');
    }
    if (filterRM.state.selectedType.isNotEmpty) {
      final hasWajibUI = filterRM.state.selectedType.contains('WAJIB_UI');
      final types = filterRM.state.selectedType
          .where((type) => type != 'WAJIB_UI')
          .toList();

      if (hasWajibUI && types.isEmpty) {
        // Only "Wajib UI" selected → filter by code prefix UIGE
        data['code'] = 'UIGE';
      } else {
        // When "Wajib UI" is combined with other types, include MANDATORY
        // to capture UIGE courses (since UIGE courses are MANDATORY type)
        if (hasWajibUI && !types.contains('MANDATORY')) {
          types.add('MANDATORY');
        }
        // Include UNKNOWN as fallback for non-Fasilkom courses
        if (types.contains('MANDATORY') || types.contains('ELECTIVE')) {
          if (!types.contains('UNKNOWN')) {
            types.add('UNKNOWN');
          }
        }
        data['course_type'] = types.join(',');
      }
    }
    if (filterRM.state.selectedJurusan != null) {
      data['major'] = filterRM.state.selectedJurusan!;
    }

    return Uri(queryParameters: data).query;
  }
}
