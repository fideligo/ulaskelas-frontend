String getFinalGrade(double score) {
  var grade = 'E';
  switch (score) {
    case >= 85:
      grade = 'A';
    case >= 80:
      grade = 'A-';
    case >= 75:
      grade = 'B+';
    case >= 70:
      grade = 'B';
    case >= 65:
      grade = 'B-';
    case >= 60:
      grade = 'C+';
    case >= 55:
      grade = 'C';
    case >= 40:
      grade = 'D';
  }

  return grade;
}

// Round to 2 decimal places and remove trailing zeros
String formatDouble(double value) {
  return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
}

/// The course type label (`Wajib` / `Pilihan`) for a course subtitle.
///
/// The backend omits `code_desc` for non-Fasilkom faculties, and every
/// `fromJson` in the app falls that field back to the course code itself
/// (`codeDesc = json['code_desc'] ?? code`). A `codeDesc` equal to the code
/// therefore carries no type information — printing it renders the code twice,
/// e.g. `PSPS609011   PSPS609011`. Those cases fall back to `Wajib`.
String courseTypeLabel(String? codeDesc, String? code) {
  final label = codeDesc?.trim() ?? '';
  if (label.isEmpty || label == (code?.trim() ?? '')) {
    return 'Wajib';
  }
  return label;
}
