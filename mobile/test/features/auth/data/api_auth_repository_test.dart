import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/auth/data/api_auth_repository.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

import '../../../helpers/fake_session_store.dart';

/// Answers every request with the status and body chosen by the test.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.status, [this.body = '']);

  final int status;
  final String body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _newSessionBody =
    '{'
    '"accessToken":"access-2",'
    '"accessTokenExpiresAt":"2026-10-27T09:30:00+00:00",'
    '"refreshToken":"refresh-2",'
    '"refreshTokenExpiresAt":"2026-11-03T09:15:00+00:00",'
    '"mustChangePassword":false'
    '}';

AuthSession _storedSession() => AuthSession(
  accessToken: 'access-1',
  accessTokenExpiresAt: DateTime.utc(2026, 10, 27, 9, 15),
  refreshToken: 'refresh-1',
  refreshTokenExpiresAt: DateTime.utc(2026, 11, 3, 9),
  mustChangePassword: false,
);

ApiAuthRepository _repository(_FakeServer server, FakeSessionStore store) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = server;
  return ApiAuthRepository(ApiClient(dio), store);
}

void main() {
  group('signIn', () {
    test('stores the session and sends the credentials', () async {
      final server = _FakeServer(200, _newSessionBody);
      final store = FakeSessionStore();

      final result = await _repository(
        server,
        store,
      ).signIn(userName: 'demo.operator', password: 'Demo-Password-1');

      expect(result, isA<Ok<AuthSession>>());
      expect(store.session?.refreshToken, 'refresh-2');
      expect(server.requests.single.path, '/api/auth/login');
      expect(server.requests.single.data, {
        'userName': 'demo.operator',
        'password': 'Demo-Password-1',
      });
    });

    test('stores nothing when the password is wrong', () async {
      final server = _FakeServer(401);
      final store = FakeSessionStore();

      final result = await _repository(
        server,
        store,
      ).signIn(userName: 'demo.operator', password: 'wrong');

      expect((result as Err<AuthSession>).failure, isA<UnauthorizedFailure>());
      expect(store.session, isNull);
    });
  });

  group('refresh', () {
    test('sends the stored refresh token and keeps the new session', () async {
      final server = _FakeServer(200, _newSessionBody);
      final store = FakeSessionStore(_storedSession());

      final result = await _repository(server, store).refresh();

      expect(result, isA<Ok<AuthSession>>());
      expect(server.requests.single.data, {'refreshToken': 'refresh-1'});
      expect(store.session?.refreshToken, 'refresh-2');
    });

    test('forgets the session when the server refuses it', () async {
      final server = _FakeServer(401);
      final store = FakeSessionStore(_storedSession());

      await _repository(server, store).refresh();

      expect(store.session, isNull);
    });

    test('keeps the session when the server is unavailable', () async {
      final server = _FakeServer(503);
      final store = FakeSessionStore(_storedSession());

      final result = await _repository(server, store).refresh();

      expect((result as Err<AuthSession>).failure, isA<ServerFailure>());
      expect(store.session?.refreshToken, 'refresh-1');
    });

    test('does not call the server without a stored session', () async {
      final server = _FakeServer(200, _newSessionBody);

      final result = await _repository(server, FakeSessionStore()).refresh();

      expect((result as Err<AuthSession>).failure, isA<UnauthorizedFailure>());
      expect(server.requests, isEmpty);
    });
  });

  test('signOut forgets the session even when the server fails', () async {
    final server = _FakeServer(503);
    final store = FakeSessionStore(_storedSession());

    await _repository(server, store).signOut();

    expect(store.session, isNull);
    expect(server.requests.single.path, '/api/auth/logout');
    expect(server.requests.single.data, {'refreshToken': 'refresh-1'});
  });
}
