import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/auth/data/session_store.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// [AuthRepository] backed by the API's `/api/auth` endpoints.
@LazySingleton(as: AuthRepository)
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._store);

  final ApiClient _api;
  final SessionStore _store;

  @override
  Future<Result<AuthSession>> signIn({
    required String userName,
    required String password,
  }) async {
    final result = await _api.post(
      '/api/auth/login',
      body: {'userName': userName, 'password': password},
      parse: AuthSession.fromJson,
    );

    if (result case Ok(:final value)) {
      await _store.write(value);
    }

    return result;
  }

  @override
  Future<AuthSession?> currentSession() => _store.read();

  @override
  Future<Result<AuthSession>> refresh() async {
    final session = await _store.read();
    if (session == null) {
      return const Err(UnauthorizedFailure());
    }

    final result = await _api.post(
      '/api/auth/refresh',
      body: {'refreshToken': session.refreshToken},
      parse: AuthSession.fromJson,
    );

    if (result case Ok(:final value)) {
      await _store.write(value);
    } else if (result case Err(failure: UnauthorizedFailure())) {
      // The server ended this session (expired, revoked or reused): forget it.
      await _store.clear();
    }

    // Any other failure (no network, server error) keeps the session:
    // a later refresh can still succeed.
    return result;
  }

  @override
  Future<Result<CurrentUser>> me() {
    return _api.get('/api/auth/me', parse: CurrentUser.fromJson);
  }

  @override
  Future<void> signOut() async {
    final session = await _store.read();

    // Forget it on the device first, so signing out works even offline.
    await _store.clear();

    if (session != null) {
      // Best effort: if the server cannot be reached, the token simply expires.
      await _api.post<void>(
        '/api/auth/logout',
        body: {'refreshToken': session.refreshToken},
        parse: (_) {},
      );
    }
  }
}
