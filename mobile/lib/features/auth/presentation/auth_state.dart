import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

/// Who is using the app right now. The router and every page read this.
sealed class AuthState {
  const AuthState();
}

/// The app has just started and the stored session is being checked.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// Nobody is signed in, or the session has ended.
final class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// A user is signed in.
final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final CurrentUser user;
}

/// A session is stored, but the server could not be asked about it
/// (no network, server error). The user can try again.
final class AuthUnavailable extends AuthState {
  const AuthUnavailable(this.failure);

  final Failure failure;
}
