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
    this.facultyName,
    this.onTap,
    this.onDelete,
    this.isDisabled = false,
  });

  final String? name;
  final int? sks;

  /// `Wajib` / `Pilihan`.
  final String? type;

  final String? code;

  /// Faculty name for the crest, e.g. `ILMU KOMPUTER`. Null falls the crest
  /// back to the course-code heuristic.
  final String? facultyName;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Drops this row from the list it is drawn in. Null renders no trash
  /// button at all, which is how rows the student may not remove are drawn.
  final VoidCallback? onDelete;

  /// Draws the row as inert — halved opacity, flat background, no taps.
  ///
  /// For courses that are on the list for information only and that no action
  /// here can change, e.g. the SLCM duplicates the import already skips.
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final isLive = isSelected && !isDisabled;
    final card = AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: double.infinity,
        // Tightened on the right when the trash button is there, so its own
        // tap target supplies the padding instead of doubling up on it.
        padding: EdgeInsets.fromLTRB(14, 12, onDelete == null ? 14 : 4, 12),
        decoration: BoxDecoration(
          color: isLive ? BaseColors.white : BaseColors.gray5,
          boxShadow:
              isLive ? BoxShadowDecorator().defaultShadow(context) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _checkbox(),
            const WidthSpace(12),
            FacultyLogo(
              code: code,
              facultyName: facultyName,
            ),
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
            if (onDelete != null) _deleteButton(),
          ],
        ),
      ),
    );

    // Swallows the gesture rather than leaning on a null `onTap`, so a row
    // marked inert stays inert whatever the caller passes.
    if (isDisabled) {
      return IgnorePointer(child: card);
    }
    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }

  double get _opacity {
    if (isDisabled) {
      return 0.5;
    }
    return isSelected ? 1 : 0.55;
  }

  Widget _checkbox() {
    if (isDisabled) {
      // Ticked but grey: the course is accounted for and the student cannot
      // act on it, which an empty box would invite them to try.
      return Container(
        height: 22,
        width: 22,
        decoration: BoxDecoration(
          color: BaseColors.gray3,
          border: Border.all(
            color: BaseColors.gray3,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 16,
          color: BaseColors.white,
        ),
      );
    }
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

  /// A Material glyph, not a Cupertino one, so the button is drawn on Android
  /// as well as iOS.
  Widget _deleteButton() {
    return IconButton(
      onPressed: onDelete,
      icon: const Icon(
        Icons.delete_outline,
        color: BaseColors.error,
      ),
      iconSize: 22,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      tooltip: 'Hapus dari daftar',
    );
  }

  /// `4 SKS   Wajib   CSGE602070`, ellipsized so a long name or code cannot
  /// overflow the row on a narrow screen.
  Widget _details() {
    return Text(
      courseSubtitle(sks: sks, codeDesc: type, code: code),
      style: FontTheme.poppins12w400black().copyWith(
        color: BaseColors.gray2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
