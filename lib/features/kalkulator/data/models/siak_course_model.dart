import 'package:ulaskelas/features/matkul/search/data/models/_models.dart';

/// A course read off the student's IRS in SIAK for one semester.
///
/// Shaped for the scrape endpoint that does not exist yet — this model is
/// currently filled by the mock generator in `AutoFillState`, so keep
/// [SiakCourseModel.fromJson] in step with the eventual response.
class SiakCourseModel {
  SiakCourseModel({
    this.id,
    this.name,
    this.code,
    this.sks,
    this.type,
    this.faculties,
  });

  /// Adapts a catalogue course into the shape the review step reads.
  ///
  /// The manual picker works with `CourseModel`, so the two entry points into
  /// the review screen have to agree on one shape. Worth replacing with a
  /// shared course type once the review step is real.
  SiakCourseModel.fromCourse(CourseModel course) {
    id = course.id;
    name = course.name;
    code = course.code;
    sks = course.sks;
    type = course.codeDesc;
    faculties = course.faculties;
  }

  SiakCourseModel.fromJson(Map<String, dynamic> json) {
    id = json['course_id'];
    name = json['course_name'];
    code = json['course_code'];
    sks = json['course_sks'];
    type = json['course_type'];
    final rawFaculties = json['faculties'];
    if (rawFaculties is List) {
      faculties = rawFaculties
          .whereType<Map<String, dynamic>>()
          .map(FacultyModel.fromJson)
          .toList();
    }
  }

  /// Local `Course.id`. The import posts ids, not codes, so losing this on the
  /// way through the review step makes the confirm step throw on a null check.
  int? id;

  String? name;

  /// Course code as printed in SIAK, e.g. `CSGE602070`.
  String? code;

  int? sks;

  /// `Wajib` or `Pilihan`.
  String? type;

  /// Faculties offering this course, carried over from the catalogue course.
  /// Null until the scrape endpoint exists and returns it.
  List<FacultyModel>? faculties;

  /// The faculty the crest is drawn from. See [CourseModel.facultyName].
  String? get facultyName {
    final list = faculties;
    if (list == null || list.isEmpty) {
      return null;
    }
    return list.first.name;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['course_id'] = id;
    data['course_name'] = name;
    data['course_code'] = code;
    data['course_sks'] = sks;
    data['course_type'] = type;
    data['faculties'] = faculties?.map((f) => f.toJson()).toList();
    return data;
  }
}
