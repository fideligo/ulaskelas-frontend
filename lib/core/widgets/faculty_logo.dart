import 'package:flutter/material.dart';

/// Course-code prefix → crest filename in `assets/faculties/`.
///
/// A SIAK code opens with two letters naming the faculty that owns the course
/// — `CSCM603117` (Fasilkom), `LWET600153` (Hukum), `UIGE600001` (MPKT, the
/// university's own). That prefix is the only owner signal the app can trust.
/// The `faculties` array on the course endpoints is built from study-program
/// mappings and sorted by name, so it lists every faculty whose curriculum
/// includes a course, with no notion of an owner; reading it handed every
/// cross-listed course to whichever faculty sorted first in the alphabet.
///
/// Values are the exact PNG basenames, which are not uniformly capitalised —
/// `FPsi` and `Vokasi` are spelled as they appear on disk. Every crest in the
/// directory is reachable from this map, and no key maps to a missing file.
const _codePrefixAssetMap = <String, String>{
  'CS': 'Fasilkom',
  'SC': 'FMIPA',
  'EN': 'FT',
  'LW': 'FH',
  'SP': 'FISIP',
  'PS': 'FPsi',
  'HM': 'FIB',
  'VO': 'Vokasi',
  'EC': 'FEB',
  'NS': 'FIK',
  'PH': 'FKM',
  'PM': 'FF',
  'AD': 'FIA',
  'DN': 'FKG',
  'MD': 'FK',
  'UI': 'UI',
};

/// Shown when the code says nothing we recognise: an unfamiliar prefix, or no
/// code at all.
///
/// The university makara is the honest answer there — every course belongs to
/// UI even when we cannot place the faculty — and unlike a faculty crest it
/// cannot misattribute one faculty's course to another.
const _fallbackSlug = 'UI';

/// The faculty crest shown at the head of a course card.
///
/// Resolution is the first two letters of [code], looked up in
/// [_codePrefixAssetMap], falling back to [_fallbackSlug]. There is no second
/// tier and no empty state: this always renders a crest.
///
/// Renders bare — no tile, tint, or background — per the unified card design.
class FacultyLogo extends StatelessWidget {
  const FacultyLogo({
    super.key,
    this.code,
    this.facultyName,
    this.width = 44,
    this.height = 48,
  });

  /// Course code, e.g. `CSGE602070`. Null when the caller has no code to give,
  /// which lands on [_fallbackSlug].
  final String? code;

  /// Retained so the call sites already passing it keep compiling.
  ///
  /// Deliberately unread. The backend's faculty names cannot identify the
  /// owning faculty of a cross-listed course — see [_codePrefixAssetMap] — so
  /// the crest no longer consults them.
  final String? facultyName;

  /// The crest box. 44×48 is the design spec; the PNG is letterboxed inside it
  /// by [BoxFit.contain], so a square source stays 44 wide and centred.
  final double width;
  final double height;

  String get _slug {
    final trimmed = code?.trim().toUpperCase() ?? '';
    if (trimmed.length < 2) {
      return _fallbackSlug;
    }
    return _codePrefixAssetMap[trimmed.substring(0, 2)] ?? _fallbackSlug;
  }

  @override
  Widget build(BuildContext context) {
    // Sized so rows stay aligned down a list whatever crest each card draws.
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/faculties/$_slug.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
