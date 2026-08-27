// Dev-only trigger UI. Every entry point is gated on Config.isDevelopment, so
// the sheet cannot be opened in a production build.

import 'package:flutter/material.dart';
import 'package:ristek_material_component/ristek_material_component.dart';
import 'package:ulaskelas/core/environment/_environment.dart';
import 'package:ulaskelas/core/theme/_theme.dart';
import 'package:ulaskelas/services/notification/_notification.dart';
import 'package:ulaskelas/services/notification/dev/dev_notification_simulator.dart';

/// Opens the simulator sheet. No-op outside the development flavor.
Future<void> showDevNotificationMenu(BuildContext context) async {
  if (!Config.isDevelopment) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: BaseColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _DevNotificationMenu(),
  );
}

class _DevNotificationMenu extends StatefulWidget {
  const _DevNotificationMenu();

  @override
  State<_DevNotificationMenu> createState() => _DevNotificationMenuState();
}

class _DevNotificationMenuState extends State<_DevNotificationMenu> {
  final _courseIdController = TextEditingController(text: '1');
  final _courseCodeController = TextEditingController(text: 'CSCM601043');

  @override
  void dispose() {
    _courseIdController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  NotificationPayload get _calculatorPayload =>
      NotificationPayload.calculator();

  NotificationPayload get _courseReviewPayload =>
      NotificationPayload.courseReview(
        courseId: _courseIdController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEV — Notification Simulator',
                style: FontTheme.poppins14w600black(),
              ),
              const HeightSpace(4),
              Text(
                'Tidak tersedia di build production.',
                style: FontTheme.poppins12w500black().copyWith(
                  color: BaseColors.gray3,
                ),
              ),
              const HeightSpace(16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _courseIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'course_id',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const WidthSpace(12),
                  Expanded(
                    child: TextField(
                      controller: _courseCodeController,
                      decoration: const InputDecoration(
                        labelText: 'course_code',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              _section('Layer 1 — route only (no tray)'),
              _row([
                _button('Kalkulator', () => _route(_calculatorPayload)),
                _button('Course Review', () => _route(_courseReviewPayload)),
              ]),
              _section('Layer 2 — real tray notification'),
              _row([
                _button('Kalkulator', () => _fire(_calculatorPayload)),
                _button('Course Review', () => _fire(_courseReviewPayload)),
              ]),
              _section('Layer 3 — scheduled +15s (swipe from recents to test)'),
              _row([
                _button('Kalkulator', () => _schedule(_calculatorPayload)),
                _button('Course Review', () => _schedule(_courseReviewPayload)),
              ]),
              _section('Badge & diagnostics'),
              _row([
                _button('Badge +1', _incrementBadge),
                _button('Badge reset', _resetBadge),
              ]),
              _row([
                _button('Print FCM token', _printToken),
                _button('Permission status', _permissionStatus),
              ]),
              _row([
                _button('Request permission', _requestPermission),
                _button('Print notif state', _printNotifState),
              ]),
              _row([
                _button('Clear tray + badge', _clearAll),
                _button('Cancel scheduled', _cancelScheduled),
              ]),
              const HeightSpace(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        label,
        style: FontTheme.poppins12w600black().copyWith(
          color: BaseColors.purpleHearth,
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const WidthSpace(12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _button(String label, Future<void> Function() onPressed) {
    return SecondaryButton(
      height: 36,
      borderRadius: BorderRadius.circular(8),
      backgroundColor: BaseColors.primary,
      text: label,
      onPressed: onPressed,
    );
  }

  Future<void> _route(NotificationPayload payload) async {
    Navigator.of(context).pop();
    await DevNotificationSimulator.route(payload);
  }

  Future<void> _fire(NotificationPayload payload) {
    return _run(
      () => DevNotificationSimulator.fire(payload),
      'Dikirim ke tray. Tap untuk menguji deep link.',
    );
  }

  Future<void> _schedule(NotificationPayload payload) {
    return _run(
      () => DevNotificationSimulator.schedule(payload),
      'Terjadwal +15 detik. Geser dari recents untuk uji terminated.',
    );
  }

  /// Both layers fail for reasons that produce no console output of their own:
  /// a missing permission raised from native alarm setup, or a post the system
  /// drops after accepting it. Letting either escape `onPressed` would leave
  /// the button looking like it succeeded, which is the exact failure mode
  /// these layers exist to catch, so every outcome is reported twice.
  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
    } catch (e, s) {
      print('[DEV SIM] failed: $e');
      print(s);
      if (!mounted) return;
      ErrorMessenger('$e').show(context);
      return;
    }
    _toast(success);
  }

  Future<void> _incrementBadge() async {
    await BadgeService.increment();
    _toast('Badge = ${BadgeService.count}');
  }

  Future<void> _resetBadge() async {
    await BadgeService.reset();
    _toast('Badge = ${BadgeService.count}');
  }

  Future<void> _clearAll() async {
    await NotificationService.clearAll();
    _toast('Tray dan badge dibersihkan.');
  }

  Future<void> _cancelScheduled() async {
    await DevNotificationSimulator.cancelScheduled();
    _toast('Jadwal dibatalkan.');
  }

  Future<void> _printToken() async {
    final token = await FcmClient.registerToken();
    _toast(
      token == null
          ? 'Token belum tersedia (izin ditolak / simulator iOS).'
          : 'Token dicetak ke console debug.',
    );
  }

  Future<void> _permissionStatus() async {
    final granted = await NotificationPermission.isGranted();
    _toast(granted ? 'Izin: granted' : 'Izin: denied / belum diminta');
  }

  /// [NotificationPermission.requestIfNeeded] fires at most once per install,
  /// so a tester who denied it on first run has no way back to the sheet. This
  /// goes straight at POST_NOTIFICATIONS, skipping that latch.
  Future<void> _requestPermission() async {
    final granted = await DevNotificationSimulator.requestPermission();
    _toast(
      granted
          ? 'Izin diberikan. Layer 2 dan 3 sekarang bisa tampil.'
          : 'Masih ditolak. Android hanya menampilkan sheet dua kali; '
              'aktifkan lewat Settings > Apps > TemanKuliah > Notifications.',
    );
  }

  Future<void> _printNotifState() async {
    final state = await DevNotificationSimulator.describeState();
    _toast(state);
  }

  void _toast(String message) {
    if (!mounted) return;
    SuccessMessenger(message).show(context);
  }
}
