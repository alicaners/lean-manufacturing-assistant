import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

/// The only access token the fake server accepts.
const String validAccessToken = 'access-2';

/// What the fake refresh endpoint returns: a session with [validAccessToken].
const String renewedSessionBody =
    '{'
    '"accessToken":"$validAccessToken",'
    '"accessTokenExpiresAt":"2026-10-27T09:30:00+00:00",'
    '"refreshToken":"refresh-2",'
    '"refreshTokenExpiresAt":"2026-11-03T09:15:00+00:00",'
    '"mustChangePassword":false'
    '}';

/// A session whose access token the fake server no longer accepts.
AuthSession expiredSession() => AuthSession(
  accessToken: 'access-1',
  accessTokenExpiresAt: DateTime.utc(2026, 10, 27, 9, 15),
  refreshToken: 'refresh-1',
  refreshTokenExpiresAt: DateTime.utc(2026, 11, 3, 9),
  mustChangePassword: false,
);

/// A session the fake server accepts.
AuthSession validSession() => AuthSession(
  accessToken: validAccessToken,
  accessTokenExpiresAt: DateTime.utc(2026, 10, 27, 9, 30),
  refreshToken: 'refresh-2',
  refreshTokenExpiresAt: DateTime.utc(2026, 11, 3, 9, 15),
  mustChangePassword: false,
);

/// A tiny stand-in for the backend: answers 200 only to requests that carry
/// [validAccessToken], and renews sessions on `/api/auth/refresh`.
class FakeAuthServer implements HttpClientAdapter {
  /// What the refresh endpoint answers: 200 with a new session, or an error code.
  int refreshStatus = 200;

  /// How long a refresh takes; long enough for parallel requests to pile up.
  Duration refreshDelay = Duration.zero;

  int refreshCalls = 0;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path == '/api/auth/refresh') {
      refreshCalls++;
      await Future<void>.delayed(refreshDelay);
      return refreshStatus == 200
          ? _json(200, renewedSessionBody)
          : _json(refreshStatus, '{}');
    }

    final authorized =
        options.headers['Authorization'] == 'Bearer $validAccessToken';
    return authorized ? _json(200, '{"ok":true}') : _json(401, '{}');
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody _json(int status, String body) {
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// A Dio that talks to [server] instead of the network.
Dio fakeDio(FakeAuthServer server) =>
    Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = server;
