import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/auth/data/auth_interceptor.dart';
import 'package:lean_assistant/features/auth/data/session_refresher.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

import '../../../helpers/fake_auth_server.dart';
import '../../../helpers/fake_session_store.dart';

/// The same wiring as in the app: one Dio with the AuthInterceptor
/// for API calls, and one plain Dio for refreshes and retries.
({ApiClient api, FakeAuthServer server, FakeSessionStore store}) _app(
  AuthSession? session,
) {
  final server = FakeAuthServer();
  final store = FakeSessionStore(session);
  final plainDio = fakeDio(server);
  final refresher = SessionRefresher(plainDio, store);
  final dio = fakeDio(server)
    ..interceptors.add(AuthInterceptor(store, refresher, plainDio));

  return (api: ApiClient(dio), server: server, store: store);
}

Object? _anything(Object? json) => json;

void main() {
  test('sends the access token with every request', () async {
    final app = _app(validSession());

    final result = await app.api.get('/api/data', parse: _anything);

    expect(result, isA<Ok<Object?>>());
    expect(
      app.server.requests.single.headers['Authorization'],
      'Bearer $validAccessToken',
    );
    expect(app.server.refreshCalls, 0);
  });

  test('renews an expired token and repeats the request', () async {
    final app = _app(expiredSession());

    final result = await app.api.get('/api/data', parse: _anything);

    expect(result, isA<Ok<Object?>>());
    expect(app.server.requests.map((request) => request.path), [
      '/api/data',
      '/api/auth/refresh',
      '/api/data',
    ]);
    expect(app.store.session?.accessToken, validAccessToken);
  });

  test('parallel requests with an expired token share one refresh', () async {
    final app = _app(expiredSession());
    app.server.refreshDelay = const Duration(milliseconds: 50);

    final results = await Future.wait(
      List.generate(5, (_) => app.api.get('/api/data', parse: _anything)),
    );

    expect(app.server.refreshCalls, 1);
    expect(results, everyElement(isA<Ok<Object?>>()));
  });

  test('gives up when the session cannot be renewed', () async {
    final app = _app(expiredSession());
    app.server.refreshStatus = 401;

    final result = await app.api.get('/api/data', parse: _anything);

    expect((result as Err<Object?>).failure, isA<UnauthorizedFailure>());
    expect(app.store.session, isNull);
    expect(
      app.server.requests.where((request) => request.path == '/api/data'),
      hasLength(1),
    );
  });

  test('leaves the sign-in endpoint alone', () async {
    final app = _app(null);

    final result = await app.api.post(
      '/api/auth/login',
      body: {'userName': 'demo.operator', 'password': 'wrong'},
      parse: _anything,
    );

    expect((result as Err<Object?>).failure, isA<UnauthorizedFailure>());
    expect(app.server.requests.single.headers['Authorization'], isNull);
    expect(app.server.refreshCalls, 0);
  });
}
