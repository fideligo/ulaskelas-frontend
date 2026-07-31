part of '_widgets.dart';

/// The faculty crest shown at the head of a course card.
///
/// Interim: `assets/faculties/` only ships Fasilkom's makara and no endpoint
/// exposes a faculty field yet, so the crest is inferred from the course code.
/// Every Fasilkom code printed in SIAK starts with `CS` (`CSGE`, `CSCM`,
/// `CSIE`, …); anything else gets a neutral icon until the other crests are
/// wired up. A missing code keeps the makara, since the calculator is
/// Fasilkom-only for now.
///
/// Renders bare — no tile, tint, or background — per the unified card design.
class FacultyLogo extends StatelessWidget {
  const FacultyLogo({
    super.key,
    this.code,
    this.size = 50,
  });

  /// Course code, e.g. `CSGE602070`. Null when the caller has no code to give.
  final String? code;

  final double size;

  bool get _isFasilkom {
    final trimmed = code?.trim().toUpperCase() ?? '';
    if (trimmed.isEmpty) {
      return true;
    }
    return trimmed.startsWith('CS');
  }

  @override
  Widget build(BuildContext context) {
    // Sized either way so rows stay aligned when a fallback sits next to a
    // crest in the same list.
    return SizedBox(
      width: size,
      height: size,
      child: _isFasilkom
          ? Image.asset(
              'assets/faculties/Fasilkom.png',
              fit: BoxFit.contain,
            )
          : Icon(
              Icons.school_rounded,
              size: size * 0.62,
              color: BaseColors.gray3,
            ),
    );
  }
}
