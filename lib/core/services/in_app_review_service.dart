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
}
