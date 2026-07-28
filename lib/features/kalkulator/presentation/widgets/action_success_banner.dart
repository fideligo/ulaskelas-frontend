part of '_widgets.dart';

/// Confirmation strip shown at the top of the detail page after the component
/// sheet closes.
///
/// An in-page widget rather than a toast on purpose: every messenger in this
/// app is a `Flushbar`, and a Flushbar is a navigator route. Keeping the
/// confirmation inside the page body means it cannot end up above a sheet and
/// be popped in its place — the crash this replaced.
class ActionSuccessBanner extends StatelessWidget {
  const ActionSuccessBanner({
    required this.message,
    super.key,
    this.onDismiss,
  });

  static const _background = Color(0xFFDCF3E4);
  static const _accent = Color(0xFF2E9E5B);
  static const _foreground = Color(0xFF1F3D2B);

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 22, color: _accent),
            const WidthSpace(12),
            Expanded(
              child: Text(
                message,
                style: FontTheme.poppins14w400black().copyWith(
                  fontSize: 13,
                  color: _foreground,
                ),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: _foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
