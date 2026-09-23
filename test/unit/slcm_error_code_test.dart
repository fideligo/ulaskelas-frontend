// The copy a student sees for each backend failure code.
//
// Pinned as literals rather than by referencing the constants, so a change to
// the wording has to be made here too and cannot slip through unreviewed.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulaskelas/features/kalkulator/domain/entities/slcm_error_code.dart';

void main() {
  group('messageFor', () {
    test('both authentication failures share the credentials message', () {
      const expected = 'Username atau password SSO tidak valid.';
      expect(SlcmErrorCode.messageFor('INVALID_CREDENTIALS'), expected);
      expect(SlcmErrorCode.messageFor('AUTHENTICATION_FAILED'), expected);
    });

    test('identity mismatch names the real problem', () {
      expect(
        SlcmErrorCode.messageFor('IDENTITY_MISMATCH'),
        'Akun SSO tidak cocok dengan profil Teman Kuliah Anda.',
      );
    });

    test('all three SLCM-side failures share one message', () {
      const expected =
          'Gagal terhubung dengan server SLCM. Silakan coba beberapa saat '
          'lagi.';
      expect(SlcmErrorCode.messageFor('SLCM_NETWORK_ERROR'), expected);
      expect(SlcmErrorCode.messageFor('SLCM_PROTOCOL_ERROR'), expected);
      expect(SlcmErrorCode.messageFor('SLCM_ERROR'), expected);
    });

    test('an unknown code returns null so the caller can fall back', () {
      // Null, not a generic string: AutoFillState uses this to decide whether
      // to show the backend's own error.message instead.
      expect(SlcmErrorCode.messageFor('SOMETHING_NEW'), isNull);
      expect(SlcmErrorCode.messageFor(null), isNull);
      expect(SlcmErrorCode.messageFor(''), isNull);
    });

    test('matching is exact - no case folding, no partial match', () {
      expect(SlcmErrorCode.messageFor('invalid_credentials'), isNull);
      expect(SlcmErrorCode.messageFor('SLCM_NETWORK_ERROR '), isNull);
    });
  });

  group('isCredentialProblem', () {
    test('true only for the two the student can retype their way out of', () {
      expect(SlcmErrorCode.isCredentialProblem('INVALID_CREDENTIALS'), isTrue);
      expect(SlcmErrorCode.isCredentialProblem('AUTHENTICATION_FAILED'), isTrue);
    });

    test('false for everything else, including identity mismatch', () {
      // A mismatch is not fixed by retyping: the account is simply the wrong
      // one, so reopening the sheet would just waste the student's time.
      expect(SlcmErrorCode.isCredentialProblem('IDENTITY_MISMATCH'), isFalse);
      expect(SlcmErrorCode.isCredentialProblem('SLCM_ERROR'), isFalse);
      expect(SlcmErrorCode.isCredentialProblem(null), isFalse);
    });
  });
}
