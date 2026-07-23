part of '_widgets.dart';

/// The recommended path: pull the semester's courses straight from SIAK.
class CardAutoFillOption extends StatelessWidget {
  const CardAutoFillOption({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF162456), Color(0xFF5D0EC0)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OptionPill(
              icon: Icons.thumb_up_rounded,
              label: 'Recommended',
              background: BaseColors.white.withOpacity(0.18),
              foreground: BaseColors.white,
            ),
            const HeightSpace(14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _logo(),
                const WidthSpace(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Fill dari SIAK',
                        style: FontTheme.poppins16w700white(),
                      ),
                      const HeightSpace(6),
                      Text(
                        'Matkul yang kamu pilih di IRS semester ini langsung '
                        'masuk otomatis. Tidak perlu input manual.',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: BaseColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const HeightSpace(14),
            const OptionPill(
              icon: Icons.check_rounded,
              label: 'Terintegrasi SSO UI',
              background: BaseColors.success,
              foreground: BaseColors.white,
            ),
          ],
        ),
      ),
    );
  }

  /// SIAK NG has no logo in the asset bundle, so a wordmark tile stands in
  /// until one is added.
  Widget _logo() {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: BaseColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          'SIAK',
          style: FontTheme.poppins10w700black().copyWith(
            color: BaseColors.purpleHearth,
          ),
        ),
      ),
    );
  }
}

/// The fallback path: search the catalogue and tick off courses by hand.
class CardManualFillOption extends StatelessWidget {
  const CardManualFillOption({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BaseColors.white,
          border: Border.all(
            color: BaseColors.purpleHearth.withOpacity(0.15),
          ),
          boxShadow: BoxShadowDecorator().defaultShadow(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OptionPill(
              icon: Icons.tune_rounded,
              label: 'Manual',
              background: BaseColors.purpleHearth.withOpacity(0.12),
              foreground: BaseColors.purpleHearth,
            ),
            const HeightSpace(14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _icon(),
                const WidthSpace(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Matkul Manual',
                        style: FontTheme.poppins16w700black(),
                      ),
                      const HeightSpace(6),
                      Text(
                        'Cari dan pilih beberapa matkul sekaligus. Cocok jika '
                        'matkul tidak terdaftar di SIAK atau mau custom',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: BaseColors.gray2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const HeightSpace(14),
            OptionPill(
              icon: Icons.check_box_rounded,
              label: 'Multi-Select Sekaligus',
              background: BaseColors.purpleHearth.withOpacity(0.12),
              foreground: BaseColors.purpleHearth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: BaseColors.purpleHearth.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.search_rounded,
          size: 22,
          color: BaseColors.purpleHearth,
        ),
      ),
    );
  }
}

/// Small rounded tag used above and below the body of a fill option.
class OptionPill extends StatelessWidget {
  const OptionPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const WidthSpace(5),
          Text(
            label,
            style: FontTheme.poppins10w700black().copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
