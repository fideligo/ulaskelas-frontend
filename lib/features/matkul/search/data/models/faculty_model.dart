part of '_models.dart';

/// One faculty that offers a course, from the `faculties` array the course
/// endpoints started returning on `feat/cross-faculty-course-catalog`.
///
/// [id] is only the faculty *segment* of the owning study program's org code —
/// the third dot-separated field, e.g. `12` out of `01.00.12.01`. It is
/// therefore **not** comparable to a major's `org_code` from `/api/majors`,
/// which is the full code; matching a course to a selected major means
/// comparing against that major's third segment.
class FacultyModel {
  FacultyModel({
    this.id,
    this.name,
  });

  FacultyModel.fromJson(Map<String, dynamic> json) {
    // Sent as a string today, but it is a numeric segment — don't let a
    // future int break parsing of the whole course list.
    id = json['id']?.toString();
    name = json['name'];
  }

  /// Faculty segment of the org code, e.g. `12`.
  String? id;

  /// Faculty name as the backend stores it, uppercase Indonesian —
  /// e.g. `ILMU KOMPUTER`.
  String? name;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}
