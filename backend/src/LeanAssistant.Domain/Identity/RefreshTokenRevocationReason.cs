namespace LeanAssistant.Domain.Identity;

/// <summary>Why a refresh token can no longer be used.</summary>
public enum RefreshTokenRevocationReason
{
    /// <summary>Exchanged for a new token (normal rotation).</summary>
    Rotated,

    /// <summary>An already used token was presented again; the whole family was closed.</summary>
    ReuseDetected,

    /// <summary>The user signed out.</summary>
    LoggedOut
}