/// Tokens of a signed-in user, as the API returns them on sign-in and refresh.
/// Also the shape kept in secure storage between app starts.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.mustChangePassword,
  });

  /// Reads the API's `AuthTokens` response.
  /// Throws [FormatException] if a field is missing or has the wrong type.
  factory AuthSession.fromJson(Object? json) {
    if (json case {
      'accessToken': final String accessToken,
      'accessTokenExpiresAt': final String accessTokenExpiresAt,
      'refreshToken': final String refreshToken,
      'refreshTokenExpiresAt': final String refreshTokenExpiresAt,
      'mustChangePassword': final bool mustChangePassword,
    }) {
      return AuthSession(
        accessToken: accessToken,
        accessTokenExpiresAt: DateTime.parse(accessTokenExpiresAt),
        refreshToken: refreshToken,
        refreshTokenExpiresAt: DateTime.parse(refreshTokenExpiresAt),
        mustChangePassword: mustChangePassword,
      );
    }

    // The JSON itself is not put into the message: it contains tokens.
    throw const FormatException('Unexpected session response.');
  }

  /// Short-lived token sent with every API request.
  final String accessToken;
  final DateTime accessTokenExpiresAt;

  /// Long-lived token, used only to get a new access token.
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;

  /// True when an admin set the password; the user must change it first.
  final bool mustChangePassword;

  /// The same shape as the API's response, so [AuthSession.fromJson] reads both.
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
    'mustChangePassword': mustChangePassword,
  };
}
