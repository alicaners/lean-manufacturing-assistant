/// What can happen to the sign-in state.
sealed class AuthEvent {
  const AuthEvent();
}

/// Check the stored session and load the user. Sent at app start,
/// after signing in, and when the user taps "try again".
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// The user tapped "sign out".
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// The server stopped accepting the session while the app was in use.
final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}
