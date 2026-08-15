import 'dart:math';

class CalculatorModel {
  String? givenSemester;
  int? id;
  String? user;
  int? courseId;
  String? courseName;
  double? totalScore;
  double? totalPercentage;
  String? shortName;
  int? courseSKS;
  String? courseCode;
  String? courseCodeDesc;

  // TODO: await faculties field from BE
  // `CalculatorSerializer` on feat/cross-faculty-course-catalog still returns
  // only id/user/course_id/course_name/course_sks/total_score/total_percentage
  // — no `faculties`. Until it does, cards fed by this model fall back to the
  // course-code heuristic in FacultyLogo.

  CalculatorModel({
    this.givenSemester,
    this.id,
    this.user,
    this.courseId,
    this.courseName,
    this.totalScore,
    this.totalPercentage,
    this.shortName,
    this.courseSKS,
    this.courseCode,
    this.courseCodeDesc,
  });

  CalculatorModel.fromJson(Map<String, dynamic> json, String givenSemester) {
    givenSemester = givenSemester;
    id = json['id'];
    user = json['user'];
    courseId = json['course_id'];
    courseName = json['course_name'];
    totalScore = json['total_score'];
    totalPercentage = json['total_percentage'];
    courseSKS = json['course_sks'];
    courseCode = json['course_code'];
    courseCodeDesc = json['course_code_desc'] ?? courseCode;
    if (courseName?.isNotEmpty ?? false) {
      shortName = courseName?.split(' ').fold<String>(
            '',
            (previousValue, element) =>
                previousValue + element.substring(0, min(element.length, 1)),
          );
      shortName = shortName!.substring(0, min(shortName!.length, 2));
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['user'] = user;
    data['course_id'] = courseId;
    data['course_name'] = courseName;
    data['total_score'] = totalScore;
    data['total_percentage'] = totalPercentage;
    data['course_sks'] = courseSKS;
    data['course_code'] = courseCode;
    data['course_code_desc'] = courseCodeDesc;
    return data;
  }
}
