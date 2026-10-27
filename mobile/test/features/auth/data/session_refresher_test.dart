import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/auth/data/session_refresher.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

import '../../../helpers/fake_auth_server.dart';
import '../../../helpers/fake_session_store.dart';

void main() {
  test('sends the stored refresh token and keeps the new session', () async {
    final server = FakeAuthServer();
    final store = FakeSessionStore(expiredSession());

    final result = await SessionRefresher(fakeDio(server), store).refresh();

    expect(result, isA<Ok<AuthSession>>());
    expect(server.requests.single.data, {'refreshToken': 'refresh-1'});
    expect(store.session?.accessToken, validAccessToken);
  });

  test(
    'forgets the session and reports it when the server refuses it',
    () async {
      final server = FakeAuthServer()..refreshStatus = 401;
      final store = FakeSessionStore(expiredSession());
      final refresher = SessionRefresher(fakeDio(server), store);
      final expired = expectLater(refresher.sessionExpired, emits(anything));

      await refresher.refresh();

      await expired;
      expect(store.session, isNull);
    },
  );

  test('keeps the session when the server is unavailable', () async {
    final server = FakeAuthServer()..refreshStatus = 503;
    final store = FakeSessionStore(expiredSession());

    final result = await SessionRefresher(fakeDio(server), store).refresh();

    expect((result as Err<AuthSession>).failure, isA<ServerFailure>());
    expect(store.session?.refreshToken, 'refresh-1');
  });

  test('does not call the server without a stored session', () async {
    final server = FakeAuthServer();

    final result = await SessionRefresher(
      fakeDio(server),
      FakeSessionStore(),
    ).refresh();

    expect((result as Err<AuthSession>).failure, isA<UnauthorizedFailure>());
    expect(server.requests, isEmpty);
  });

  test('parallel calls share one refresh', () async {
    final server = FakeAuthServer()
      ..refreshDelay = const Duration(milliseconds: 50);
    final refresher = SessionRefresher(
      fakeDio(server),
      FakeSessionStore(expiredSession()),
    );

    final results = await Future.wait([
      refresher.refresh(),
      refresher.refresh(),
      refresher.refresh(),
    ]);

    expect(server.refreshCalls, 1);
    expect(results, everyElement(isA<Ok<AuthSession>>()));
  });
}
