import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulaskelas/services/_services.dart';
import 'package:ulaskelas/services/notification/_notification.dart';

/// The park/drain queue allows a cold-start notification tap to survive the
/// splash and auth window: the tap arrives long before navigation is possible,
/// so losing it here would break every terminated-state deep link.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Pref.init();
    NotificationService.resetForTest();
  });

  test('a tap with no handler installed is parked, not dropped', () {
    final payload = NotificationPayload.calculator();

    NotificationService.handleTap(payload);

    expect(NotificationService.takePending(), payload);
  });

  test('a parked payload drains exactly once', () {
    NotificationService.handleTap(NotificationPayload.calculator());

    expect(NotificationService.takePending(), isNotNull);
    expect(NotificationService.takePending(), isNull);
  });

  test('takePending is null when nothing was ever parked', () {
    expect(NotificationService.takePending(), isNull);
  });

  test('a tap goes straight to the handler once one is installed', () {
    final seen = <NotificationPayload>[];
    NotificationService.onPayloadTapped = seen.add;

    final payload = NotificationPayload.courseReview(courseId: '42');
    NotificationService.handleTap(payload);

    expect(seen, [payload]);
    // Must not also be parked, or the router would replay it a second time.
    expect(NotificationService.takePending(), isNull);
  });

  test('park overwrites, so only the newest deep link is replayed', () {
    final first = NotificationPayload.calculator();
    final second = NotificationPayload.courseReview(courseId: '7');

    NotificationService.park(first);
    NotificationService.park(second);

    expect(NotificationService.takePending(), second);
  });
}
