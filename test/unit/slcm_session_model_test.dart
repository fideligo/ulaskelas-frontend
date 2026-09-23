// Parsing for the HTTP-session SLCM contract.
//
// Covers the two things the refactor changed shape on - the stale-data
// advisory and the removal of the noVNC popup - plus the degradation rules
// that keep a partial payload from throwing inside a poll callback.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulaskelas/features/kalkulator/data/models/slcm_session_model.dart';

/// A `_serialize` response at `ready`, with every field the contract names.
Map<String, dynamic> readySession({
  bool warningStaleData = false,
  String status = 'ready',
}) {
  return <String, dynamic>{
    'session_id': '7d0f1a1e-0000-4000-8000-000000000001',
    'given_semester': '5',
    'status': status,
    'expires_at': '2026-09-23T10:00:00Z',
    'source_period': '2026/2027 Ganjil',
    'preview': <String, dynamic>{
      'matched': [
        {'id': 1, 'code': 'CSCM603117', 'name': 'Analisis Numerik', 'sks': 3},
      ],
      'duplicates': [
        {'id': 5, 'code': 'CSCM603142', 'name': 'DAA', 'sks': 4},
      ],
      'unmatched': [
        {'code': 'XXX9001', 'name': 'Matkul Lintas', 'credits': 2},
      ],
      'warning_stale_data': warningStaleData,
    },
  };
}

void main() {
  group('ready session', () {
    test('parses the three preview buckets', () {
      final session = SlcmSessionModel.fromJson(readySession());

      expect(session.status, SlcmSessionStatus.ready);
      expect(session.sessionId, '7d0f1a1e-0000-4000-8000-000000000001');
      expect(session.givenSemester, '5');
      expect(session.sourcePeriod, '2026/2027 Ganjil');
      expect(session.preview!.matched.single.code, 'CSCM603117');
      expect(session.preview!.duplicates.single.id, 5);
      // The scraped shape spells the credit count differently.
      expect(session.preview!.unmatched.single.credits, 2);
    });

    test('warning_stale_data is read when the backend sets it', () {
      final on = SlcmSessionModel.fromJson(
        readySession(warningStaleData: true),
      );
      expect(on.preview!.warningStaleData, isTrue);

      final off = SlcmSessionModel.fromJson(readySession());
      expect(off.preview!.warningStaleData, isFalse);
    });

    test('a missing or non-boolean flag reads as "not stale"', () {
      // The import must never be held back by a malformed advisory.
      for (final raw in <dynamic>[null, 'true', 1, <String>[]]) {
        final json = readySession();
        (json['preview'] as Map<String, dynamic>)['warning_stale_data'] = raw;
        final session = SlcmSessionModel.fromJson(json);
        expect(
          session.preview!.warningStaleData,
          isFalse,
          reason: 'raw: $raw',
        );
      }

      final json = readySession();
      (json['preview'] as Map<String, dynamic>).remove('warning_stale_data');
      expect(
        SlcmSessionModel.fromJson(json).preview!.warningStaleData,
        isFalse,
      );
    });
  });

  group('status lifecycle', () {
    test('authenticating and scraping keep the poller running', () {
      expect(SlcmSessionStatus.fromWire('authenticating').isPending, isTrue);
      expect(SlcmSessionStatus.fromWire('scraping').isPending, isTrue);
    });

    test('the four settled states stop it', () {
      // `ready` is not terminal - the session lives on until confirm - but it
      // is not pending either, which is what ends the loop.
      expect(SlcmSessionStatus.fromWire('ready').isPending, isFalse);
      for (final wire in ['imported', 'failed', 'expired', 'cancelled']) {
        expect(
          SlcmSessionStatus.fromWire(wire).isTerminal,
          isTrue,
          reason: wire,
        );
      }
    });

    test('an unrecognised status parses to unknown instead of throwing', () {
      final status = SlcmSessionStatus.fromWire('some_future_state');
      expect(status, SlcmSessionStatus.unknown);
      expect(status.isPending, isFalse);
      expect(status.isTerminal, isFalse);
    });

    test('the retired waiting_login no longer resolves', () {
      // The noVNC popup is gone; nothing should still map to it.
      expect(
        SlcmSessionStatus.fromWire('waiting_login'),
        SlcmSessionStatus.unknown,
      );
    });
  });

  group('failed session', () {
    test('carries the error code the state maps to UI copy', () {
      final session = SlcmSessionModel.fromJson(<String, dynamic>{
        'session_id': 'abc',
        'status': 'failed',
        'error': <String, dynamic>{
          'code': 'INVALID_CREDENTIALS',
          'message': 'SSO rejected the supplied credentials',
        },
      });

      expect(session.status, SlcmSessionStatus.failed);
      expect(session.error!.code, 'INVALID_CREDENTIALS');
      expect(session.preview, isNull);
    });
  });

  group('degradation', () {
    test('an empty payload parses without throwing', () {
      final session = SlcmSessionModel.fromJson(<String, dynamic>{});
      expect(session.status, SlcmSessionStatus.unknown);
      expect(session.sessionId, isNull);
      expect(session.preview, isNull);
      expect(session.error, isNull);
    });

    test('a preview with no lists yields empty ones, not null', () {
      final session = SlcmSessionModel.fromJson(<String, dynamic>{
        'status': 'ready',
        'preview': <String, dynamic>{},
      });
      expect(session.preview!.matched, isEmpty);
      expect(session.preview!.duplicates, isEmpty);
      expect(session.preview!.unmatched, isEmpty);
    });

    test('an unparseable expires_at degrades to null', () {
      final json = readySession()..['expires_at'] = 'not-a-date';
      expect(SlcmSessionModel.fromJson(json).expiresAt, isNull);
    });
  });

  group('round trip', () {
    test('toJson no longer carries popup_url', () {
      // The field is gone with the noVNC flow; this is what keeps it gone.
      final json = SlcmSessionModel.fromJson(readySession()).toJson();
      expect(json.containsKey('popup_url'), isFalse);
      expect(
        (json['preview'] as Map<String, dynamic>)['warning_stale_data'],
        isFalse,
      );
    });
  });
}
