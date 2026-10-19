namespace LeanAssistant.Application.Identity;

/// <summary>What the client receives after signing in, refreshing or changing the password.</summary>
/// <param name="MustChangePassword">
/// True: the app must show the change-password screen; every other endpoint answers 403.
/// </param>
public sealed record AuthTokens(
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAt,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAt,
    bool MustChangePassword);