import 'package:lean_assistant/features/auth/data/session_store.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';

/// Keeps the session in memory instead of the phone's encrypted storage.
class FakeSessionStore implements SessionStore {
  FakeSessionStore([this.session]);

  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession value) async {
    session = value;
  }

  @override
  Future<void> clear() async {
    session = null;
  }
}
