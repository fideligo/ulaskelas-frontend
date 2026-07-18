part of '_widgets.dart';

/// Stand-in screen for a fill method that has not been built yet.
///
/// Shows which semester was carried over from the picker so the navigation
/// can be checked before the real flow lands.
class FillMethodPlaceholder extends StatelessWidget {
  const FillMethodPlaceholder({
    required this.title,
    required this.givenSemester,
    required this.message,
    super.key,
  });

  final String title;
  final String givenSemester;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseColors.white,
      appBar: BaseAppBar(
        label: title,
        centerTitle: false,
        elevation: 0,
        style: FontTheme.poppins18w700black(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: BaseColors.purpleHearth.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  semesterFullLabel(givenSemester),
                  style: FontTheme.poppins14w600black().copyWith(
                    color: BaseColors.purpleHearth,
                  ),
                ),
              ),
              const HeightSpace(20),
              Text(
                message,
                style: FontTheme.poppins12w400black().copyWith(
                  color: BaseColors.gray2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
