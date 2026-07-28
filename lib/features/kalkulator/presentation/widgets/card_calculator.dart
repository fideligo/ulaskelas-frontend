part of '_widgets.dart';

class CardCalculator extends StatelessWidget {
  const CardCalculator({
    required this.model,
    required this.givenSemester,
    super.key,
    this.onTap,
  });

  final CalculatorModel model;
  final String givenSemester;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BaseColors.gray5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Dummy makara logo
              width: 48,
              height: 48,
            ),
            const WidthSpace(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.courseName ?? '-',
                    style: FontTheme.poppins14w700black(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const HeightSpace(4),
                  Row(
                    children: [
                      Text(
                        '${model.courseSKS ?? 0} SKS',
                        style: FontTheme.poppins12w500black(),
                      ),
                      if (model.courseCodeDesc != model.courseCode && model.courseCodeDesc?.isNotEmpty == true) ...[
                        const WidthSpace(12),
                        Text(
                          model.courseCodeDesc!,
                          style: FontTheme.poppins12w500black(),
                        ),
                      ],
                      const WidthSpace(12),
                      Text(
                        model.courseCode ?? '-',
                        style: FontTheme.poppins12w500black(),
                      ),
                    ],
                  ),
                  const HeightSpace(4),
                  Text(
                    (model.totalPercentage ?? 0) > 0 
                      ? _getFinalScoreAndGrade(model.totalScore ?? 0) 
                      : 'Belum ada nilai',
                    style: FontTheme.poppins12w400black().copyWith(
                      color: BaseColors.gray2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async => _deleteCard(context),
              icon: const Icon(
                Icons.delete_outline,
                color: BaseColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCard(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => DeleteDialog(
        title: 'Hapus Matkul',
        content: 'Apakah kamu yakin ingin menghapus '
            'Kalkulator ${model.courseName}?',
        onConfirm: () async {
          nav.pop();
          await calculatorRM.setState(
            (s) => s.deleteCalculator(
              query: QueryCalculator(courseId: model.courseId),
              givenSemester: givenSemester,
              courseName: model.courseName!,
              totalScore: model.totalScore!,
            ),
          );
        },
      ),
    );
  }

  String _getFinalGradeOnly(double score) {
    if (score >= 85) return 'A';
    if (score >= 80) return 'A-';
    if (score >= 75) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 65) return 'B-';
    if (score >= 60) return 'C+';
    if (score >= 55) return 'C';
    if (score >= 40) return 'D';
    return 'E';
  }

  String _getFinalScoreAndGrade(double score) {
    final grade = _getFinalGradeOnly(score);
    return '$grade (${score.toStringAsFixed(2)})';
  }
}
