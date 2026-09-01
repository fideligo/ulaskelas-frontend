part of '_widgets.dart';

/// Outlined chip standing for one picked course, with an X to drop it.
class SelectedCoursePill extends StatelessWidget {
  const SelectedCoursePill({
    required this.label,
    super.key,
    this.onRemove,
  });

  /// Usually the course's `shortName`, e.g. `BD`.
  final String label;

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
      decoration: BoxDecoration(
        border: Border.all(color: BaseColors.purpleHearth),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FontTheme.poppins12w600black().copyWith(
              color: BaseColors.purpleHearth,
            ),
          ),
          const WidthSpace(6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: BaseColors.purpleHearth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
