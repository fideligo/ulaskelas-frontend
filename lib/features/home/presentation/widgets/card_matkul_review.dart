part of '_widgets.dart';

class CardMatkulReview extends StatelessWidget {
  const CardMatkulReview({
    required this.review, super.key,
    this.onTap,
  });

  final ReviewModel review;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd/MM/yyyy').format(review.createdAt!);
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
        child: Column(
          children: [
            Row(
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
                        review.courseName.toString(),
                        style: FontTheme.poppins14w700black().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const HeightSpace(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '4 SKS   Wajib   ${review.courseCode ?? '-'}',
                            style: FontTheme.poppins12w400black(),
                          ),
                          Text(
                            '${review.courseReviewCount} Ulasan',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeightSpace(4),
                Container(
                  padding: const EdgeInsets.only(bottom: 10, top: 8),
                  child: Text(
                    'Anda: ${review.content}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FontTheme.poppins12w400black().copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diulas pada $formattedDate',
                      style: FontTheme.poppins10w400black().copyWith(
                        color: BaseColors.gray2,
                      ),
                    ),
                    Tag(
                      label: review.hateSpeechStatus.toString(),
                      state: review.hateSpeechStatus == 'APPROVED'
                          ? TagStatus.approved
                          : (review.hateSpeechStatus == 'WAITING')
                              ? TagStatus.pending
                              : TagStatus.rejected,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
