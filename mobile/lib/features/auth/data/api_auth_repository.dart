import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/auth/data/session_refresher.dart';
import 'package:lean_assistant/features/auth/data/session_store.dart';
import 'package:lean_assistant/features/auth/domain/auth_repository.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// [AuthRepository] backed by the API's `/api/auth` endpoints.
@LazySingleton(as: AuthRepository)
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._store, this._refresher);

  final ApiClient _api;
  final SessionStore _store;
  final SessionRefresher _refresher;

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

  /// Shares the refresher with the interceptor, so an explicit refresh
  /// and an automatic one can never run at the same time.
  @override
  Future<Result<AuthSession>> refresh() => _refresher.refresh();

  @override
  Stream<void> get sessionExpired => _refresher.sessionExpired;

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
