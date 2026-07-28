part of '_widgets.dart';

/// Stands in for the purple target-grade card while the rubric is incomplete.
///
/// Ruby cannot recommend anything until the component weights add up to 100%,
/// so rather than show a prediction built on a partial rubric, the card says
/// how far along the setup is and what is still missing.
class SetupBobotReminderCard extends StatelessWidget {
  const SetupBobotReminderCard({
    required this.totalWeight,
    super.key,
  });

  static const _background = Color(0xFFFEFCE8);

  /// Border, bar fill, percentage and footer all share one amber.
  static const _accent = Color(0xFFF0B100);
  static const _track = Color(0xFFE3E5E8);

  /// Sum of every component's weight, in percent.
  final double totalWeight;

  @override
  Widget build(BuildContext context) {
    // A rubric can be over-filled past 100 while still not being valid, so the
    // bar is clamped rather than allowed to overflow.
    final progress = (totalWeight / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/ruby/ruby_sad.png', height: 40),
              const WidthSpace(10),
              Expanded(
                child: Text(
                  'Setup Bobot Komponen',
                  style: FontTheme.poppins14w700black(),
                ),
              ),
              const WidthSpace(8),
              Text(
                '${formatDouble(totalWeight)}%',
                style: FontTheme.poppins16w700black().copyWith(
                  fontSize: 20,
                  color: _accent,
                ),
              ),
            ],
          ),
          const HeightSpace(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _track,
              valueColor: const AlwaysStoppedAnimation(_accent),
            ),
          ),
          const HeightSpace(10),
          Text(
            'Tambah komponen sampai 100% untuk aktifkan Rekomendasi Ruby',
            style: FontTheme.poppins12w500black().copyWith(
              fontSize: 12.5,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }
}
