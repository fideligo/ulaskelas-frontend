part of '_repositories.dart';

/// Contract for the SLCM autofill session flow.
///
/// Every method resolves to a [Decide] so the caller folds the failure branch
/// instead of catching: the `apiCall` wrapper in the implementation is what
/// turns a `DioException` into a `TimeoutFailure`/`NetworkFailure` and what
/// forces the SSO redirect on a 403.
abstract class SlcmAutofillRepository {
  Future<Decide<Failure, Parsed<SlcmSessionModel>>> createSession(
    String givenSemester,
  );

  Future<Decide<Failure, Parsed<SlcmSessionModel>>> getSession(
    String sessionId,
  );

  Future<Decide<Failure, Parsed<void>>> deleteSession(String sessionId);

  Future<Decide<Failure, Parsed<SlcmSessionModel>>> confirmSession(
    String sessionId,
  );
}
