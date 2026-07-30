part of '_widgets.dart';

class CardCourseSimplified extends StatelessWidget {
  const CardCourseSimplified({
    required this.model,
    this.isChecked = false,
    super.key,
    // this.onTap,
  });

  final CourseModel model;
  // final VoidCallback? onTap;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!isChecked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isChecked ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: isChecked 
              ? Border.all(color: const Color(0xFF4921B8), width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(
                horizontal: -4,
                vertical: -4,
              ),
              activeColor: const Color(0xFF4921B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              value: isChecked,
              onChanged: onChanged,
            ),
            const WidthSpace(12),
            Image.asset(
              'assets/images/logo.png', // Dummy makara logo
              width: 48,
              height: 48,
            ),
            const WidthSpace(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name.toString(),
                    style: FontTheme.poppins14w700black(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const HeightSpace(4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          model.codeDesc != model.code && model.codeDesc?.isNotEmpty == true
                              ? '${model.sks ?? 0} SKS   ${model.codeDesc}   ${model.code ?? '-'}'
                              : '${model.sks ?? 0} SKS   ${model.code ?? '-'}',
                          style: FontTheme.poppins12w500black(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onChanged(bool? isChecked) {
    if (isChecked != null) {
      if (isChecked) {
        searchCourseRM.state.addCourse(model);
      } else {
        searchCourseRM.state.removeCourse(model);
      }
    }

    if (kDebugMode) {
      final printCourses = <String>[];
      for (final course in searchCourseRM.state.selectedCourses) {
        printCourses.add(course.name!);
      }
      print(printCourses);
    }
  }
}
