part of '_repositories.dart';

class SlcmAutofillRepositoryImpl implements SlcmAutofillRepository {
  SlcmAutofillRepositoryImpl(
    this._remoteDataSource,
  );

  final SlcmAutofillRemoteDataSource _remoteDataSource;

  @override
  Future<Decide<Failure, Parsed<SlcmSessionModel>>> createSession(
    String givenSemester,
  ) {
    return apiCall(_remoteDataSource.createSession(givenSemester));
  }

  @override
  Future<Decide<Failure, Parsed<SlcmSessionModel>>> getSession(
    String sessionId,
  ) {
    return apiCall(_remoteDataSource.getSession(sessionId));
  }

  @override
  Future<Decide<Failure, Parsed<void>>> deleteSession(String sessionId) {
    return apiCall(_remoteDataSource.deleteSession(sessionId));
  }

  @override
  Future<Decide<Failure, Parsed<SlcmSessionModel>>> confirmSession(
    String sessionId,
  ) {
    return apiCall(_remoteDataSource.confirmSession(sessionId));
  }
}
