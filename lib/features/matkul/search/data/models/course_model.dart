// Created by Muhamad Fauzi Ridwan on 07/11/21.

part of '_models.dart';

class CourseModel {
  CourseModel({
    this.id,
    this.code,
    this.curriculum,
    this.name,
    this.description,
    this.sks,
    this.term,
    this.prerequisites,
    this.reviewCount,
    this.codeDesc,
    this.tags,
    this.ratingAverage,
    this.ratingUnderstandable,
    this.ratingFitToCredit,
    this.ratingFitToStudyBook,
    this.ratingBeneficial,
    this.ratingRecommended,
    this.faculties,
  });

  CourseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    codeDesc = json['code_desc'] ?? code;
    curriculum = json['curriculum'];
    name = json['name'];
    description = json['description'];
    sks = json['sks'];
    term = json['term'];
    prerequisites = json['prerequisites'];
    reviewCount = json['review_count'];
    if (name?.isNotEmpty ?? false) {
      shortName = name?.split(' ').fold<String>(
            '',
            (previousValue, element) =>
                previousValue + element.substring(0, min(element.length, 1)),
          );
      shortName = shortName!.substring(0, min(shortName!.length, 2));
    }
    if (description?.isEmpty ?? true) {
      description = 'Tidak ada deskripsi';
    }

    if (json['tags'] != null) {
      tags = json['tags'].cast<String>();
    }
    ratingAverage = json['rating_average'];
    ratingUnderstandable = json['rating_understandable'];
    ratingFitToCredit = json['rating_fit_to_credit'];
    ratingFitToStudyBook = json['rating_fit_to_study_book'];
    ratingBeneficial = json['rating_beneficial'];
    ratingRecommended = json['rating_recommended'];
    final rawFaculties = json['faculties'];
    if (rawFaculties is List) {
      faculties = rawFaculties
          .whereType<Map<String, dynamic>>()
          .map(FacultyModel.fromJson)
          .toList();
    }
  }

  int? id;
  String? code;
  String? codeDesc;
  String? curriculum;
  String? name;
  String? description;
  int? sks;
  int? term;
  String? prerequisites;
  int? reviewCount;
  String? shortName;
  List<String>? tags;
  double? ratingAverage;
  double? ratingUnderstandable;
  double? ratingFitToCredit;
  double? ratingFitToStudyBook;
  double? ratingBeneficial;
  double? ratingRecommended;

  /// Faculties offering this course. Null when the deployed backend predates
  /// `feat/cross-faculty-course-catalog`; empty when the course has no active
  /// study-program mapping.
  List<FacultyModel>? faculties;

  /// The faculty the crest is drawn from — the backend sorts `faculties` by
  /// name, so the first entry is stable between requests.
  ///
  /// A cross-faculty course belongs to several; one crest is all a card row
  /// has space for.
  String? get facultyName {
    final list = faculties;
    if (list == null || list.isEmpty) {
      return null;
    }
    return list.first.name;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['code_desc'] = codeDesc;
    data['curriculum'] = curriculum;
    data['name'] = name;
    data['description'] = description;
    data['sks'] = sks;
    data['term'] = term;
    data['prerequisites'] = prerequisites;
    data['review_count'] = reviewCount;
    data['tags'] = tags;
    data['rating_average'] = ratingAverage;
    data['rating_understandable'] = ratingUnderstandable;
    data['rating_fit_to_credit'] = ratingFitToCredit;
    data['rating_fit_to_study_book'] = ratingFitToStudyBook;
    data['rating_beneficial'] = ratingBeneficial;
    data['rating_recommended'] = ratingRecommended;
    data['faculties'] = faculties?.map((f) => f.toJson()).toList();
    return data;
  }

  @override
  bool operator ==(Object other) {
    if (other is CourseModel) {
      return code == other.code || id == other.id;
    }
    return super == other;
  }

  @override
  int get hashCode => super.hashCode;

  String get describe {
    final type = courseTypeLabel(codeDesc, code);
    final base = '$code  •  $sks SKS';
    return type == null ? base : '$base  •  $type';
  }
  String get cleanedDesc =>
      description?.isEmpty ?? true ? 'Tidak ada deskripsi' : '$description';
}
