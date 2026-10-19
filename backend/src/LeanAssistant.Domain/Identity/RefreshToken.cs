using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.Domain.Identity;

/// <summary>
/// A long-lived token used to get new access tokens without signing in again.
/// Only a hash of the token is stored; the token itself is known only to the device.
/// </summary>
/// <remarks>
/// Every token belongs to a family: the chain of tokens that started with one sign-in.
/// Each refresh replaces the current token with a new one in the same family (rotation).
/// If a token that was already replaced is presented again, someone else may have a copy,
/// so the whole family is revoked.
/// </remarks>
public sealed class RefreshToken : Entity
{
    // Used by EF Core when it reads a token from the database.
    private RefreshToken()
    {
    }

    private RefreshToken(Guid userId, Guid familyId, string tokenHash, DateTimeOffset expiresAt)
    {
        UserId = userId;
        FamilyId = familyId;
        TokenHash = tokenHash;
        ExpiresAt = expiresAt;
    }

    public Guid UserId { get; private set; }

    /// <summary>Same for every token created from one sign-in.</summary>
    public Guid FamilyId { get; private set; }

    /// <summary>SHA-256 hash of the token, never the token itself.</summary>
    public string TokenHash { get; private set; } = null!;

    public DateTimeOffset ExpiresAt { get; private set; }

    public DateTimeOffset? RevokedAt { get; private set; }

    public RefreshTokenRevocationReason? RevocationReason { get; private set; }

    /// <summary>The token that replaced this one during rotation.</summary>
    public Guid? ReplacedByTokenId { get; private set; }

    public bool IsRevoked => RevokedAt is not null;

    public bool IsExpired(DateTimeOffset now) => now >= ExpiresAt;

    public bool IsActive(DateTimeOffset now) => !IsRevoked && !IsExpired(now);

    /// <summary>Creates the first token of a new family, at sign-in.</summary>
    public static RefreshToken IssueNewFamily(
        Guid userId, string tokenHash, DateTimeOffset now, TimeSpan lifetime) =>
        Issue(userId, Guid.CreateVersion7(), tokenHash, now, lifetime);

    /// <summary>
    /// Replaces this token with a new one in the same family and revokes this one.
    /// </summary>
    public RefreshToken Rotate(string newTokenHash, DateTimeOffset now, TimeSpan lifetime)
    {
        if (!IsActive(now))
        {
            throw new InvalidOperationException("Only an active refresh token can be rotated.");
        }

        var next = Issue(UserId, FamilyId, newTokenHash, now, lifetime);

        Revoke(now, RefreshTokenRevocationReason.Rotated);
        ReplacedByTokenId = next.Id;

        return next;
    }

    /// <summary>Revokes the token. Revoking twice keeps the first reason and time.</summary>
    public void Revoke(DateTimeOffset now, RefreshTokenRevocationReason reason)
    {
        if (IsRevoked)
        {
            return;
        }

        RevokedAt = now;
        RevocationReason = reason;
    }

    private static RefreshToken Issue(
        Guid userId, Guid familyId, string tokenHash, DateTimeOffset now, TimeSpan lifetime)
    {
        if (userId == Guid.Empty)
        {
            throw new ArgumentException("User id is required.", nameof(userId));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(tokenHash);

        if (lifetime <= TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(nameof(lifetime), "Lifetime must be positive.");
        }

        return new RefreshToken(userId, familyId, tokenHash, now + lifetime);
    }
}