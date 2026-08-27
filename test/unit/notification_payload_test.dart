import 'package:flutter_test/flutter_test.dart';
import 'package:ulaskelas/core/constants/_constants.dart';
import 'package:ulaskelas/services/notification/_notification.dart';

void main() {
  group('NotificationPayload.fromMap', () {
    test('reads the calculator contract', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'calculator_reminder',
        'target': 'grade_calculator',
      });

      expect(payload.type, NotificationType.calculatorReminder);
      expect(payload.target, NotificationTarget.gradeCalculator);
      expect(payload.isCalculator, isTrue);
      expect(payload.isCourseReview, isFalse);
      expect(payload.isSupported, isTrue);
      expect(payload.courseIdValue, isNull);
    });

    test('reads the course review contract', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'course_review_reminder',
        'target': 'course_review',
        'course_id': '123',
        'course_code': 'CSCM601043',
      });

      expect(payload.isCourseReview, isTrue);
      expect(payload.courseIdValue, 123);
      expect(payload.courseCode, 'CSCM601043');
    });

    test('ignores the extra keys the backend sends alongside the contract', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'calculator_reminder',
        'target': 'grade_calculator',
        'notification_id': '42',
        'badge': '3',
      });

      expect(payload.isSupported, isTrue);
      expect(payload.isCalculator, isTrue);
    });

    test('falls back to the target implied by type when target is absent', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'course_review_reminder',
        'course_id': '9',
      });

      expect(payload.target, isNull);
      expect(payload.routingTarget, NotificationTarget.courseReview);
      expect(payload.isCourseReview, isTrue);
      expect(payload.isSupported, isTrue);
    });

    test('routes on target even when the type is unrecognised', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'some_future_reminder',
        'target': 'grade_calculator',
      });

      expect(payload.isSupported, isTrue);
      expect(payload.isCalculator, isTrue);
    });

    test('treats an unknown type as unsupported instead of throwing', () {
      final payload = NotificationPayload.fromMap(
        const {'type': 'SOMETHING_NEW'},
      );

      expect(payload.isSupported, isFalse);
      expect(payload.isCalculator, isFalse);
      expect(payload.isCourseReview, isFalse);
    });

    test('rejects the retired uppercase contract', () {
      final payload = NotificationPayload.fromMap(const {'type': 'CALCULATOR'});

      expect(payload.isSupported, isFalse);
    });

    test('survives a payload with no type at all', () {
      final payload = NotificationPayload.fromMap(const <String, dynamic>{});

      expect(payload.type, isEmpty);
      expect(payload.isSupported, isFalse);
    });

    test('courseIdValue is null when course_id is not numeric', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'course_review_reminder',
        'course_id': 'not-a-number',
      });

      expect(payload.courseIdValue, isNull);
    });

    test('blank and whitespace-only values collapse to null', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'course_review_reminder',
        'course_id': '   ',
        'course_code': '',
      });

      expect(payload.courseId, isNull);
      expect(payload.courseCode, isNull);
    });

    test('coerces non-string values, as FCM may deliver numbers in tests', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'course_review_reminder',
        'course_id': 456,
      });

      expect(payload.courseId, '456');
      expect(payload.courseIdValue, 456);
    });
  });

  group('NotificationPayload.tryParse', () {
    test('round-trips through toJsonString', () {
      final original = NotificationPayload.courseReview(
        courseId: '77',
        courseCode: 'CSGE602070',
        title: 'Judul',
        body: 'Isi',
      );

      final restored = NotificationPayload.tryParse(original.toJsonString());

      expect(restored, original);
    });

    test('omits null fields from the encoded map', () {
      final payload = NotificationPayload.calculator();

      expect(payload.toMap().containsKey('course_id'), isFalse);
      expect(payload.toMap()['type'], NotificationType.calculatorReminder);
      expect(payload.toMap()['target'], NotificationTarget.gradeCalculator);
    });

    test('returns null for malformed json rather than throwing', () {
      expect(NotificationPayload.tryParse('{not json'), isNull);
    });

    test('returns null for null and empty input', () {
      expect(NotificationPayload.tryParse(null), isNull);
      expect(NotificationPayload.tryParse(''), isNull);
    });

    test('returns null when json is valid but not an object', () {
      expect(NotificationPayload.tryParse('[1,2,3]'), isNull);
      expect(NotificationPayload.tryParse('"a string"'), isNull);
    });
  });

  group('NotificationType', () {
    test('only the two story [C] triggers are routable', () {
      expect(
        NotificationType.isSupported('calculator_reminder'),
        isTrue,
      );
      expect(
        NotificationType.isSupported('course_review_reminder'),
        isTrue,
      );
      expect(NotificationType.isSupported('CALCULATOR'), isFalse);
      expect(NotificationType.isSupported(null), isFalse);
    });

    test('maps each type onto the screen it opens', () {
      expect(
        NotificationType.targetFor('calculator_reminder'),
        NotificationTarget.gradeCalculator,
      );
      expect(
        NotificationType.targetFor('course_review_reminder'),
        NotificationTarget.courseReview,
      );
      expect(NotificationType.targetFor('unknown'), isNull);
    });
  });

  group('NotificationTarget', () {
    test('only the two backend targets are accepted', () {
      expect(NotificationTarget.isSupported('grade_calculator'), isTrue);
      expect(NotificationTarget.isSupported('course_review'), isTrue);
      expect(NotificationTarget.isSupported('COURSE_REVIEW'), isFalse);
      expect(NotificationTarget.isSupported(null), isFalse);
    });
  });
}
