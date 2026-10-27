import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

// The exact shape of the API's response, including its 7-digit fractions.
const _apiJson = <String, Object?>{
  'accessToken': 'access-1',
  'accessTokenExpiresAt': '2026-10-27T09:15:00.6120038+00:00',
  'refreshToken': 'refresh-1',
  'refreshTokenExpiresAt': '2026-11-03T09:00:00+00:00',
  'mustChangePassword': false,
};

void main() {
  test('reads the sign-in response of the API', () {
    final session = AuthSession.fromJson(_apiJson);

    expect(session.accessToken, 'access-1');
    expect(session.refreshToken, 'refresh-1');
    expect(session.mustChangePassword, isFalse);
    expect(
      session.accessTokenExpiresAt
          .difference(DateTime.utc(2026, 10, 27, 9, 15))
          .inSeconds,
      0,
    );
  });

  test('survives the round trip through storage', () {
    final session = AuthSession.fromJson(_apiJson);

    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.accessToken, session.accessToken);
    expect(restored.refreshToken, session.refreshToken);
    expect(restored.accessTokenExpiresAt, session.accessTokenExpiresAt);
    expect(restored.refreshTokenExpiresAt, session.refreshTokenExpiresAt);
    expect(restored.mustChangePassword, session.mustChangePassword);
  });

  test('rejects a response without a refresh token', () {
    final json = Map<String, Object?>.of(_apiJson)..remove('refreshToken');

    expect(() => AuthSession.fromJson(json), throwsFormatException);
  });
}
