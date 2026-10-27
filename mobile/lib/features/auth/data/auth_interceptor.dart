import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/dio_names.dart';
import 'package:lean_assistant/features/auth/data/session_refresher.dart';
import 'package:lean_assistant/features/auth/data/session_store.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

/// Adds the access token to every request. When the server answers 401,
/// renews the session once and repeats the request with the new token,
/// so callers never see an expired token.
@lazySingleton
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._store,
    this._refresher,
    @Named(refreshDioName) this._retryDio,
  );

  static const String _header = 'Authorization';
  static const String _retriedKey = 'auth.retried';

  /// These endpoints manage the session themselves: they get no token,
  /// and a 401 from them is an answer (wrong password, session over),
  /// not a reason to refresh.
  static const Set<String> _sessionEndpoints = {
    '/api/auth/login',
    '/api/auth/refresh',
    '/api/auth/logout',
  };

  final SessionStore _store;
  final SessionRefresher _refresher;
  final Dio _retryDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_sessionEndpoints.contains(options.path)) {
      final session = await _store.read();
      if (session != null) {
        options.headers[_header] = _bearer(session);
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final canRenew =
        err.response?.statusCode == 401 &&
        !_sessionEndpoints.contains(request.path) &&
        request.extra[_retriedKey] != true;

    if (!canRenew) {
      handler.next(err);
      return;
    }

    final session = await _newerSession(request);
    if (session == null) {
      handler.next(err);
      return;
    }

    try {
      final response = await _retryDio.fetch<Object?>(
        request.copyWith(
          headers: {...request.headers, _header: _bearer(session)},
          extra: {...request.extra, _retriedKey: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// A session newer than the one the failed request was sent with,
  /// or null when the session cannot be renewed.
  Future<AuthSession?> _newerSession(RequestOptions request) async {
    final stored = await _store.read();
    if (stored != null && request.headers[_header] != _bearer(stored)) {
      // Another request renewed the session while this one was on its way.
      return stored;
    }

    final result = await _refresher.refresh();
    return switch (result) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  static String _bearer(AuthSession session) => 'Bearer ${session.accessToken}';
}
