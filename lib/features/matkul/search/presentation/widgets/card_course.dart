// Created by Muhamad Fauzi Ridwan on 07/11/21.

part of '_widgets.dart';

class CardCourse extends StatelessWidget {
  const CardCourse({
    required this.model, super.key,
    this.onTap,
  });

  final CourseModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    model.name.toString(),
                    style: FontTheme.poppins14w700black().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const HeightSpace(4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        model.codeDesc != model.code && model.codeDesc?.isNotEmpty == true
                            ? '${model.sks} SKS   ${model.codeDesc}   ${model.code}'
                            : '${model.sks} SKS   ${model.code}',
                        style: FontTheme.poppins12w500black(),
                      ),
                      Text(
                        '${model.reviewCount} Ulasan',
                        style: FontTheme.poppins12w400black().copyWith(
                          color: BaseColors.gray2,
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
}
