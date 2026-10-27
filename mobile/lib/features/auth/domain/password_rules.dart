/// Length limits for passwords. Mirrors the backend's PasswordRules,
/// so most mistakes are caught before a request is sent.
abstract final class PasswordRules {
  static const int minimumLength = 12;
  static const int maximumLength = 128;
}
