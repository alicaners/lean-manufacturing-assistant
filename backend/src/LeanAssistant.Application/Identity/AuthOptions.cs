namespace LeanAssistant.Application.Identity;

/// <summary>
/// Settings for signing in and tokens. Bound from the "Auth" configuration section.
/// The signing key is a secret: it comes from User Secrets or an environment variable,
/// never from appsettings.json.
/// </summary>
public sealed class AuthOptions
{
    public const string SectionName = "Auth";

    /// <summary>HMAC-SHA256 needs a key of at least 256 bits (32 bytes).</summary>
    public const int MinimumSigningKeyLength = 32;

    /// <summary>Who created the token (this API).</summary>
    public string Issuer { get; init; } = string.Empty;

    /// <summary>Who the token is meant for (the mobile app).</summary>
    public string Audience { get; init; } = string.Empty;

    public string SigningKey { get; init; } = string.Empty;

    public TimeSpan AccessTokenLifetime { get; init; } = TimeSpan.FromMinutes(15);

    public TimeSpan RefreshTokenLifetime { get; init; } = TimeSpan.FromDays(7);

    public bool IsValid() =>
        !string.IsNullOrWhiteSpace(Issuer)
        && !string.IsNullOrWhiteSpace(Audience)
        && SigningKey.Length >= MinimumSigningKeyLength
        && AccessTokenLifetime > TimeSpan.Zero
        && RefreshTokenLifetime > AccessTokenLifetime;
}