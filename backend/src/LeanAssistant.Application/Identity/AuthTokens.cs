namespace LeanAssistant.Application.Identity;

/// <summary>What the client receives after signing in or refreshing.</summary>
public sealed record AuthTokens(
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAt,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAt);