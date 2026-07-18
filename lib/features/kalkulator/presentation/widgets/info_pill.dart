part of '_widgets.dart';

/// Small read-only tag, used for the course meta row (type, SKS, semester).
class InfoPill extends StatelessWidget {
  const InfoPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BaseColors.purpleHearth.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: FontTheme.poppins12w500black().copyWith(
          color: BaseColors.purpleHearth,
        ),
      ),
    );
  }
}
