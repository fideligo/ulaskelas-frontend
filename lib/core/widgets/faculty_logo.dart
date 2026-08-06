import 'package:flutter/material.dart';
import 'package:ulaskelas/core/theme/_theme.dart';

/// Backend faculty name → crest filename in `assets/faculties/`.
///
/// Keys are the names as `study_program.faculty` stores them: uppercase
/// Indonesian, no `Fakultas` prefix. Every slug here has a matching PNG.
///
/// The three university-level keys are defensive. `get_faculties` builds the
/// array from a course's study-program mappings, so `study_program.faculty` is
/// always a real faculty — nothing in the current backend emits any of them.
/// They cost nothing and mean a future university-owned org unit lands on the
/// makara instead of a neutral icon; the branch that actually puts the UI crest
/// on MPKT today is the course-code one in [FacultyLogo].
const _facultyAssetMap = <String, String>{
  'UNIVERSITAS INDONESIA': 'UI',
  'UNIVERSITAS': 'UI',
  'MKU': 'UI',
  'ILMU KOMPUTER': 'Fasilkom',
  'EKONOMI': 'FEB',
  'TEKNIK': 'FT',
  'MATEMATIKA & ILMU PENGETAHUAN ALAM': 'FMIPA',
  'ILMU PENGETAHUAN BUDAYA': 'FIB',
  'ILMU SOSIAL & ILMU POLITIK': 'FISIP',
  'KEDOKTERAN': 'FK',
  'KEDOKTERAN GIGI': 'FKG',
  'KESEHATAN MASYARAKAT': 'FKM',
  'ILMU ADMINISTRASI': 'FIA',
  'ILMU KEPERAWATAN': 'FIK',
  'FARMASI': 'FF',
  'HUKUM': 'FH',
  'PSIKOLOGI': 'FPsi',
  'VOKASI': 'Vokasi',
};

/// Resolves a backend faculty name to its crest slug, or null when the name is
/// absent or not one we ship a crest for.
///
/// The name is normalised before lookup because casing and spacing are not
/// guaranteed across SSO and SunJad, and the two spell the conjunction both
/// ways (`MATEMATIKA DAN ILMU...` / `MATEMATIKA & ILMU...`). Folding ` DAN `
/// onto ` & ` only ever turns a miss into a hit — it cannot mis-map a name
/// that already matched.
String? facultyAssetSlug(String? facultyName) {
  final normalized = facultyName
      ?.trim()
      .toUpperCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' DAN ', ' & ');
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return _facultyAssetMap[normalized];
}

/// The faculty crest shown at the head of a course card.
///
/// Resolution order:
/// 1. [code], when it marks a university-wide course — see [_isUniversityCode].
///    This outranks [facultyName] on purpose: the backend derives `faculties`
///    from a course's study-program mappings, so on MPKT the array is every
///    faculty that teaches it, not an owner. Reading it there would stamp
///    whichever faculty sorts first onto a course the university owns.
/// 2. [facultyName] — the course's own faculty, from the `faculties` array on
///    the course endpoints. This is the only branch that is actually correct
///    for a non-Fasilkom course.
/// 3. [code] — the legacy heuristic, for callers whose model has no faculty
///    yet (anything fed by `CalculatorModel`). Every Fasilkom code printed in
///    SIAK starts with `CS` (`CSGE`, `CSCM`, `CSIE`, …). A missing code also
///    keeps the makara, since the calculator is Fasilkom-only for now.
/// 4. A neutral icon, when none of them says anything.
///
/// Renders bare — no tile, tint, or background — per the unified card design.
class FacultyLogo extends StatelessWidget {
  const FacultyLogo({
    super.key,
    this.code,
    this.facultyName,
    this.width = 44,
    this.height = 46,
  });

  /// Course code, e.g. `CSGE602070`. Null when the caller has no code to give.
  final String? code;

  /// Faculty name as the backend spells it, e.g. `ILMU KOMPUTER`. Null when
  /// the caller's model does not carry one.
  final String? facultyName;

  /// The crest box. 44×46 is the design spec; the PNG is letterboxed inside it
  /// by [BoxFit.contain], so a square source stays 44 wide and centred.
  final double width;
  final double height;

  bool get _isFasilkomCode {
    final trimmed = code?.trim().toUpperCase() ?? '';
    if (trimmed.isEmpty) {
      return true;
    }
    return trimmed.startsWith('CS');
  }

  /// Whether the code belongs to the university rather than a faculty: MPKT,
  /// Agama, Olahraga/Seni and the rest of what SIAK files under `UIGE`
  /// ("Wajib UI" in `course_prefixes.json`), plus the `UIST` stream. Faculty
  /// prefixes are the faculty's own initials — `CS`, `EN`, `ECON` — so none of
  /// them opens with `UI` and the check cannot swallow a faculty course.
  ///
  /// An empty code is not university-wide; it stays with [_isFasilkomCode].
  bool get _isUniversityCode {
    return code?.trim().toUpperCase().startsWith('UI') ?? false;
  }

  String? get _slug {
    if (_isUniversityCode) {
      return 'UI';
    }
    return facultyAssetSlug(facultyName) ??
        (_isFasilkomCode ? 'Fasilkom' : null);
  }

  @override
  Widget build(BuildContext context) {
    final slug = _slug;

    // Sized either way so rows stay aligned when a fallback sits next to a
    // crest in the same list.
    return SizedBox(
      width: width,
      height: height,
      child: slug != null
          ? Image.asset(
              'assets/faculties/$slug.png',
              fit: BoxFit.contain,
            )
          : Icon(
              Icons.school_rounded,
              size: (width < height ? width : height) * 0.5,
              color: BaseColors.gray3,
            ),
    );
  }
}
