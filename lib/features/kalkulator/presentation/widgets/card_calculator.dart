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
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: BaseColors.white,
              boxShadow: BoxShadowDecorator().defaultShadow(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                ),
                const WidthSpace(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.courseName.toString(),
                        style: FontTheme.poppins14w500black().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const HeightSpace(4),
                      Row(
                        children: [
                          Text(
                            '${model.courseSKS} SKS \u00B7 ',
                            style: FontTheme.poppins12w400black().copyWith(
                              fontSize: 13,
                              color: BaseColors.gray2,
                            ),
                          ),
                          if (model.totalPercentage == 100)
                            Text(
                              'nilai lengkap',
                              style: FontTheme.poppins12w400black().copyWith(
                                fontSize: 13,
                                color: BaseColors.success,
                              ),
                            )
                          else if ((model.totalPercentage ?? 0) > 0)
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: BaseColors.gray2),
                                const WidthSpace(2),
                                Text(
                                  'Bobot ${model.totalPercentage?.toStringAsFixed(0)}%',
                                  style: FontTheme.poppins12w400black().copyWith(
                                    fontSize: 13,
                                    color: BaseColors.gray2,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'belum ada nilai',
                              style: FontTheme.poppins12w400black().copyWith(
                                fontSize: 13,
                                color: BaseColors.gray2,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const WidthSpace(12),
                Text(
                  (model.totalPercentage ?? 0) > 0 ? _getFinalGradeOnly(model.totalScore!) : '-',
                  style: FontTheme.poppins14w700black().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: (model.totalPercentage == 100) ? BaseColors.success : BaseColors.gray2,
                  ),
                ),
                const WidthSpace(8),
                IconButton(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 3,
                  ),
                  constraints: const BoxConstraints(),
                  onPressed: () async => _deleteCard(context),
                  icon: SvgPicture.asset(
                    SvgIcons.trash,
                    width: 16,
                    height: 18,
                  ),
                  color: BaseColors.danger,
                ),
              ],
            ),
          ),
        ],
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
