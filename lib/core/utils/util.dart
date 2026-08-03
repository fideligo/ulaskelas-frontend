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

/// The course type label (`Wajib` / `Pilihan`), or null when the backend did
/// not give us one.
///
/// The backend omits `code_desc` for non-Fasilkom faculties, and every
/// `fromJson` in the app falls that field back to the course code itself
/// (`codeDesc = json['code_desc'] ?? code`). A `codeDesc` equal to the code
/// therefore carries no type information — printing it renders the code twice,
/// e.g. `PSPS609011   PSPS609011`. Rather than assume a type for those, this
/// returns null and callers drop the segment.
String? courseTypeLabel(String? codeDesc, String? code) {
  final label = codeDesc?.trim() ?? '';
  if (label.isEmpty || label == (code?.trim() ?? '')) {
    return null;
  }
  return label;
}

/// A course card subtitle: `4 SKS   Wajib Fakultas   CSGE602070`.
///
/// Collapses to `3 SKS   PSPS609011` when the course has no type, so the
/// separator closes up instead of leaving a gap where the label would be.
String courseSubtitle({int? sks, String? codeDesc, String? code}) {
  final type = courseTypeLabel(codeDesc, code);
  final trimmedCode = code?.trim() ?? '';
  return <String>[
    '${sks ?? 0} SKS',
    if (type != null) type,
    if (trimmedCode.isEmpty) '-' else trimmedCode,
  ].join('   ');
}
