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
              FacultyLogo(code: code),
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

  /// `4 SKS   Wajib   CSGE602070`, ellipsized so a long name or code cannot
  /// overflow the row on a narrow screen.
  Widget _details() {
    return Text(
      '${sks ?? 0} SKS   ${type ?? '-'}   ${code ?? '-'}',
      style: FontTheme.poppins12w400black().copyWith(
        color: BaseColors.gray2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
