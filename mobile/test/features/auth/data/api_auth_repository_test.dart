import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/core/network/api_client.dart';
import 'package:lean_assistant/features/auth/data/api_auth_repository.dart';
import 'package:lean_assistant/features/auth/data/session_refresher.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

import '../../../helpers/fake_auth_server.dart';
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

ApiAuthRepository _repository(_FakeServer server, FakeSessionStore store) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = server;
  return ApiAuthRepository(ApiClient(dio), store, SessionRefresher(dio, store));
}

void main() {
  group('signIn', () {
    test('stores the session and sends the credentials', () async {
      final server = _FakeServer(200, renewedSessionBody);
      final store = FakeSessionStore();

      final result = await _repository(
        server,
        store,
      ).signIn(userName: 'demo.operator', password: 'Demo-Password-1');

      expect(result, isA<Ok<AuthSession>>());
      expect(store.session?.accessToken, validAccessToken);
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

  test('changePassword keeps the new session from the server', () async {
    final server = _FakeServer(200, renewedSessionBody);
    final store = FakeSessionStore(expiredSession());

    final result = await _repository(server, store).changePassword(
      currentPassword: 'Temporary-Password-1',
      newPassword: 'My-Own-Password-2',
    );

    expect(result, isA<Ok<AuthSession>>());
    expect(store.session?.accessToken, validAccessToken);
    expect(server.requests.single.path, '/api/auth/change-password');
    expect(server.requests.single.data, {
      'currentPassword': 'Temporary-Password-1',
      'newPassword': 'My-Own-Password-2',
    });
  });

  test('signOut forgets the session even when the server fails', () async {
    final server = _FakeServer(503);
    final store = FakeSessionStore(expiredSession());

    await _repository(server, store).signOut();

    expect(store.session, isNull);
    expect(server.requests.single.path, '/api/auth/logout');
    expect(server.requests.single.data, {'refreshToken': 'refresh-1'});
  });
}
