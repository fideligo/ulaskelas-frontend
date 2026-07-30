// Display helpers for the grade calculator.
//
// The backend stores a semester either as a plain term number ('1'..'12') or
// as a short semester ('sp_<year>'), so every place that sorts or labels a
// semester has to decode the same two shapes.

/// Sort key that places `sp_<year>` between the two regular terms of its
/// academic year.
///
/// For a 2022 student `'sp_2025'` ranks 6.5, so it sits above `'6'` and below
/// `'7'`. Returns 0 when the id cannot be decoded, which parks it at the
/// bottom of a descending sort instead of letting it win as "active".
double semesterRank(String givenSemester, int userGeneration) {
  if (givenSemester.contains('sp')) {
    final year = int.tryParse(givenSemester.split('_').last);
    if (year == null || userGeneration <= 0) {
      return 0;
    }
    return (year - userGeneration) * 2 + 0.5;
  }
  return double.tryParse(givenSemester) ?? 0;
}

/// `'6'` -> `'Semester 6'`, `'sp_2025'` -> `'Semester Pendek 2025'`.
String semesterFullLabel(String givenSemester) {
  if (givenSemester.contains('sp')) {
    return 'Semester Pendek ${givenSemester.substring(3)}';
  }
  return 'Semester $givenSemester';
}

/// `'6'` -> `'6'`, `'sp_2025'` -> `'SP 2025'`. For tight spots like the
/// `Sem 6 Aktif` badge.
String semesterShortLabel(String givenSemester) {
  if (givenSemester.contains('sp')) {
    return 'SP ${givenSemester.substring(3)}';
  }
  return givenSemester;
}

/// SIAK's name for a term, e.g. `Semester GENAP 2025/2026`.
///
/// A regular academic year covers two terms, so semesters 5 and 6 of a 2023
/// intake both sit in 2025/2026. A short semester closes the year it runs in,
/// so `sp_2025` reads as 2024/2025.
String academicTermLabel(String givenSemester, int userGeneration) {
  if (givenSemester.contains('sp')) {
    final year = int.tryParse(givenSemester.split('_').last);
    if (year == null) {
      return 'SP';
    }
    return 'SP ${year - 1}/$year';
  }

  final term = int.tryParse(givenSemester);
  if (term == null || userGeneration <= 0) {
    final label = semesterFullLabel(givenSemester);
    return label.startsWith('Semester ') ? label.substring(9) : label;
  }

  final startYear = userGeneration + (term - 1) ~/ 2;
  final parity = term.isEven ? 'GENAP' : 'GANJIL';
  return '$parity $startYear/${startYear + 1}';
}

/// Every semester a student can add, in study order: the two regular terms of
/// an academic year followed by that year's short semester.
///
/// The short semester years follow the student's generation — a 2025 intake
/// gets `sp_2026` .. `sp_2030` — so this list is never hardcoded.
List<String> semesterCatalogue(int userGeneration) {
  return [
    '1',
    '2',
    'sp_${userGeneration + 1}',
    '3',
    '4',
    'sp_${userGeneration + 2}',
    '5',
    '6',
    'sp_${userGeneration + 3}',
    '7',
    '8',
    'sp_${userGeneration + 4}',
    '9',
    '10',
    'sp_${userGeneration + 5}',
    '11',
    '12',
  ];
}

/// A GPA as shown to the user, or `-` when there is none yet.
///
/// A semester with nothing filled in comes back as `-0.0`, which would
/// otherwise render as `-0.00`. No GPA can be negative, so clamp at zero.
String formatGpa(double? gpa) {
  if (gpa == null) {
    return '-';
  }
  return (gpa <= 0 ? 0.0 : gpa).toStringAsFixed(2);
}

/// [formatGpa] for the cumulative GPA, which the repository hands over
/// already formatted as a string.
String formatGpaString(String gpa) {
  final parsed = double.tryParse(gpa);
  return parsed == null ? gpa : formatGpa(parsed);
}
