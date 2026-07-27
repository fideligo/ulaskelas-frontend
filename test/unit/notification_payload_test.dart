import 'package:flutter_test/flutter_test.dart';
import 'package:ulaskelas/core/constants/_constants.dart';
import 'package:ulaskelas/services/notification/_notification.dart';

void main() {
  group('NotificationPayload.fromMap', () {
    test('reads the calculator contract', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'CALCULATOR',
      });

      expect(payload.type, NotificationType.calculator);
      expect(payload.isCalculator, isTrue);
      expect(payload.isCourseReview, isFalse);
      expect(payload.isSupported, isTrue);
      expect(payload.courseId, isNull);
    });

    test('reads the course review contract', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'COURSE_REVIEW',
        'matkul_id': '123',
        'course_code': 'CSCM601043',
      });

      expect(payload.isCourseReview, isTrue);
      expect(payload.courseId, 123);
      expect(payload.courseCode, 'CSCM601043');
    });

    test('treats an unknown type as unsupported instead of throwing', () {
      final payload = NotificationPayload.fromMap(
        const {'type': 'SOMETHING_NEW'},
      );

      expect(payload.isSupported, isFalse);
      expect(payload.isCalculator, isFalse);
      expect(payload.isCourseReview, isFalse);
    });

    test('survives a payload with no type at all', () {
      final payload = NotificationPayload.fromMap(const <String, dynamic>{});

      expect(payload.type, isEmpty);
      expect(payload.isSupported, isFalse);
    });

    test('courseId is null when matkul_id is not numeric', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'COURSE_REVIEW',
        'matkul_id': 'not-a-number',
      });

      expect(payload.courseId, isNull);
    });

    test('blank and whitespace-only values collapse to null', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'COURSE_REVIEW',
        'matkul_id': '   ',
        'course_code': '',
      });

      expect(payload.matkulId, isNull);
      expect(payload.courseCode, isNull);
    });

    test('coerces non-string values, as FCM may deliver numbers in tests', () {
      final payload = NotificationPayload.fromMap(const {
        'type': 'COURSE_REVIEW',
        'matkul_id': 456,
      });

      expect(payload.matkulId, '456');
      expect(payload.courseId, 456);
    });
  });

  group('NotificationPayload.tryParse', () {
    test('round-trips through toJsonString', () {
      final original = NotificationPayload.courseReview(
        matkulId: '77',
        courseCode: 'CSGE602070',
        title: 'Judul',
        body: 'Isi',
      );

      final restored = NotificationPayload.tryParse(original.toJsonString());

      expect(restored, original);
    });

    test('omits null fields from the encoded map', () {
      final payload = NotificationPayload.calculator();

      expect(payload.toMap().containsKey('matkul_id'), isFalse);
      expect(payload.toMap()['type'], NotificationType.calculator);
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
      expect(NotificationType.isSupported('CALCULATOR'), isTrue);
      expect(NotificationType.isSupported('COURSE_REVIEW'), isTrue);
      expect(NotificationType.isSupported('calculator'), isFalse);
      expect(NotificationType.isSupported(null), isFalse);
    });
  });
}
