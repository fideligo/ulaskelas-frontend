import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:ulaskelas/core/bases/states/_states.dart';

class InAppReviewService {
  static final InAppReviewService instance = InAppReviewService._internal();

  factory InAppReviewService() {
    return instance;
  }

  InAppReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    try {
      if (kDebugMode) {
        print('[InAppReview] requestReview() called in Debug Mode - showing Dummy Dialog...');
        final ctx = nav.navigatorKey.currentContext;
        if (ctx != null) {
          await _showDummyReviewDialog(ctx);
        } else {
          print('[InAppReview] Context is null, cannot show dialog.');
        }
        return;
      }

      final isAvailable = await _inAppReview.isAvailable();
      if (isAvailable) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[InAppReview] Error: $e');
      }
    }
  }

  Future<void> _showDummyReviewDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulasi In-App Review (Debug)'),
        content: const Text(
            'Popup In-App Review asli dari Google Play Store gagal dimunculkan '
            'karena aplikasi ini sedang berjalan di mode Debug/Lokal.\n\n'
            'Dialog dummy ini dibuat agar kamu bisa memvalidasi secara visual '
            'bahwa flow pemanggilan review-nya sudah benar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Beri Rating Bintang 5!'),
          ),
        ],
      ),
    );
  }
}
