/// Failure codes `views_slcm_autofill.py` puts in `error.code`, and the copy
/// the student sees for each.
///
/// The mapping lives here rather than inline in the state so it can be tested
/// without a session, and so the three SLCM-side transport failures keep
/// answering with one message instead of drifting apart.
///
/// [messageFor] returns null for a code this build has not been taught. The
/// caller then falls back to the backend's own `error.message`, and only then
/// to a generic line — so a new backend code still surfaces something useful
/// rather than being swallowed.
abstract class SlcmErrorCode {
  /// SSO rejected the username/password pair.
  static const String invalidCredentials = 'INVALID_CREDENTIALS';

  /// SSO accepted nothing — expired account, locked, or a changed login flow.
  /// Same remedy as [invalidCredentials] from the student's side.
  static const String authenticationFailed = 'AUTHENTICATION_FAILED';

  /// The SSO account signed in, but it is not the one this Teman Kuliah
  /// profile belongs to. Importing would file another student's courses.
  static const String identityMismatch = 'IDENTITY_MISMATCH';

  /// SLCM was unreachable.
  static const String slcmNetworkError = 'SLCM_NETWORK_ERROR';

  /// SLCM answered, but not in a shape the importer could read — usually a
  /// markup change on their side.
  static const String slcmProtocolError = 'SLCM_PROTOCOL_ERROR';

  /// Anything else that went wrong on the SLCM leg.
  static const String slcmError = 'SLCM_ERROR';

  static const String _credentialsMessage =
      'Username atau password SSO tidak valid.';

  static const String _identityMessage =
      'Akun SSO tidak cocok dengan profil Teman Kuliah Anda.';

  static const String _slcmMessage =
      'Gagal terhubung dengan server SLCM. Silakan coba beberapa saat lagi.';

  /// Whether the student can fix this by retyping their credentials. The
  /// sheet reopens prefilled on these rather than dropping them back to the
  /// calculator.
  static bool isCredentialProblem(String? code) {
    return code == invalidCredentials || code == authenticationFailed;
  }

  /// The message for [code], or null when it is not one this build knows.
  static String? messageFor(String? code) {
    switch (code) {
      case invalidCredentials:
      case authenticationFailed:
        return _credentialsMessage;
      case identityMismatch:
        return _identityMessage;
      case slcmNetworkError:
      case slcmProtocolError:
      case slcmError:
        return _slcmMessage;
      default:
        return null;
    }
  }
}
