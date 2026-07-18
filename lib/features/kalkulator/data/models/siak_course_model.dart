/// A course read off the student's IRS in SIAK for one semester.
///
/// Shaped for the scrape endpoint that does not exist yet — this model is
/// currently filled by the mock generator in `AutoFillState`, so keep
/// [SiakCourseModel.fromJson] in step with the eventual response.
class SiakCourseModel {
  SiakCourseModel({
    this.name,
    this.code,
    this.sks,
    this.type,
  });

  SiakCourseModel.fromJson(Map<String, dynamic> json) {
    name = json['course_name'];
    code = json['course_code'];
    sks = json['course_sks'];
    type = json['course_type'];
  }

  String? name;

  /// Course code as printed in SIAK, e.g. `CSGE602070`.
  String? code;

  int? sks;

  /// `Wajib` or `Pilihan`.
  String? type;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['course_name'] = name;
    data['course_code'] = code;
    data['course_sks'] = sks;
    data['course_type'] = type;
    return data;
  }
}
