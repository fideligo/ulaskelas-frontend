part of '_widgets.dart';

/// A tickable course row.
///
/// Takes plain fields rather than a model so both course shapes can use it:
/// `SiakCourseModel` from the auto-fill scrape and `CourseModel` from the
/// catalogue search.
class CourseChecklistCard extends StatelessWidget {
  const CourseChecklistCard({
    required this.name,
    required this.isSelected,
    super.key,
    this.sks,
    this.type,
    this.code,
    this.onTap,
  });

  final String? name;
  final int? sks;

  /// `Wajib` / `Pilihan`.
  final String? type;

  final String? code;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isSelected ? 1 : 0.55,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? BaseColors.white : BaseColors.gray5,
            boxShadow:
                isSelected ? BoxShadowDecorator().defaultShadow(context) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _checkbox(),
              const WidthSpace(12),
              _facultyLogo(),
              const WidthSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '-',
                      style: FontTheme.poppins14w600black(),
                    ),
                    const HeightSpace(3),
                    _details(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkbox() {
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        color: isSelected ? BaseColors.purpleHearth : BaseColors.transparent,
        border: Border.all(
          color: isSelected ? BaseColors.purpleHearth : BaseColors.gray3,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: BaseColors.white,
            )
          : null,
    );
  }

  /// The faculty crest is not in the asset bundle, so a tinted tile stands in.
  Widget _facultyLogo() {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: BaseColors.purpleHearth.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(
          Icons.school_rounded,
          size: 20,
          color: BaseColors.purpleHearth,
        ),
      ),
    );
  }

  /// `4 SKS · Wajib · CSGE602070`
  Widget _details() {
    final style = FontTheme.poppins12w400black().copyWith(
      color: BaseColors.gray2,
    );

    return Row(
      children: [
        Text('${sks ?? 0} SKS', style: style),
        const WidthSpace(10),
        Text(type ?? '-', style: style),
        const WidthSpace(10),
        Flexible(
          child: Text(
            code ?? '-',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
