import 'dart:async';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/core/network/dio_names.dart';
import 'package:lean_assistant/features/auth/data/session_store.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

/// Renews the session with the refresh token, one refresh at a time.
///
/// The server rotates refresh tokens and treats a reused one as theft:
/// if two requests refreshed with the same token, the second one would
/// end the whole session. So while a refresh is running, every other
/// caller waits for it and receives the same result.
@lazySingleton
class SessionRefresher {
  SessionRefresher(@Named(refreshDioName) Dio dio, this._store)
    : _api = ApiClient(dio);

  final ApiClient _api;
  final SessionStore _store;
  final StreamController<void> _expired = StreamController<void>.broadcast();

  Future<Result<AuthSession>>? _inFlight;

  /// Fires when the server no longer accepts the session:
  /// the user must sign in again.
  Stream<void> get sessionExpired => _expired.stream;

  Future<Result<AuthSession>> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<Result<AuthSession>> _refresh() async {
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
      // The server ended this session (expired, revoked or reused).
      await _store.clear();
      _expired.add(null);
    }

    // Any other failure (no network, server error) keeps the session:
    // a later refresh can still succeed.
    return result;
  }
}
