import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/auth/data/session_store.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

final _session = AuthSession(
  accessToken: 'access-1',
  accessTokenExpiresAt: DateTime.utc(2026, 10, 27, 9, 15),
  refreshToken: 'refresh-1',
  refreshTokenExpiresAt: DateTime.utc(2026, 11, 3, 9),
  mustChangePassword: false,
);

void main() {
  // flutter_secure_storage talks to the platform; tests use its built-in fake.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps the session until it is cleared', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = SecureSessionStore(const FlutterSecureStorage());

    await store.write(_session);
    expect((await store.read())?.refreshToken, 'refresh-1');

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('treats a damaged entry as signed out and removes it', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSessionStore.storageKey: 'not json',
    });
    const storage = FlutterSecureStorage();
    final store = SecureSessionStore(storage);

    expect(await store.read(), isNull);
    expect(await storage.read(key: SecureSessionStore.storageKey), isNull);
  });
}
