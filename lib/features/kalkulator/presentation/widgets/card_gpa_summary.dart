part of '_widgets.dart';

/// Header card of the calculator home: cumulative GPA, a hide toggle, and a
/// badge naming the semester currently in progress.
class CardGpaSummary extends StatelessWidget {
  const CardGpaSummary({
    required this.gpa,
    required this.badge,
    required this.isHidden,
    required this.onToggleVisibility,
    super.key,
  });

  /// Already masked by the state when [isHidden] — rendered as given.
  final String gpa;

  /// e.g. `Sem 6 Aktif`. Hidden when there is no semester yet.
  final String badge;

  final bool isHidden;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF44309F), Color(0xFF5C48D6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -45, top: -60, child: _glow(160)),
          Positioned(right: 55, bottom: -75, child: _glow(120)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'IPK',
                          style: FontTheme.poppins14w500white(),
                        ),
                      ),
                    ),
                    if (badge.isNotEmpty) _badge(),
                  ],
                ),
                const HeightSpace(4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(gpa, style: FontTheme.poppins32w700white()),
                    const WidthSpace(6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        '/ 4.00',
                        style: FontTheme.poppins14w500white().copyWith(
                          color: BaseColors.white.withOpacity(0.75),
                        ),
                      ),
                    ),
                    const WidthSpace(10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: onToggleVisibility,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: BaseColors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: BaseColors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(badge, style: FontTheme.poppins12w500white()),
    );
  }

  /// Soft circle that gives the flat gradient a bit of depth.
  Widget _glow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BaseColors.white.withOpacity(0.06),
      ),
    );
  }
}
