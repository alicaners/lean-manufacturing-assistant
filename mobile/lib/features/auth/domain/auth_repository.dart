import 'package:lean_assistant/core/error/result.dart';
import 'package:lean_assistant/features/auth/domain/auth_session.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// Sign-in, session and profile operations.
abstract interface class AuthRepository {
  /// Signs in and keeps the session on the device.
  Future<Result<AuthSession>> signIn({
    required String userName,
    required String password,
  });

  /// The session kept on the device, if any. No network call.
  Future<AuthSession?> currentSession();

  /// Exchanges the refresh token for a new session and keeps it.
  /// Forgets the session if the server no longer accepts it.
  Future<Result<AuthSession>> refresh();

  /// The signed-in user's profile.
  Future<Result<CurrentUser>> me();

  /// Forgets the session on the device and revokes it on the server.
  /// Works offline too: the device forgets the session first.
  Future<void> signOut();

  /// Fires when the server stops accepting the session while the app is in
  /// use (expired, revoked by an admin, reused): the user must sign in again.
  Stream<void> get sessionExpired;
}
