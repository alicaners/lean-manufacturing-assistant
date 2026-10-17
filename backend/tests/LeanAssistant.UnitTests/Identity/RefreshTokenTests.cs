using LeanAssistant.Domain.Identity;

namespace LeanAssistant.UnitTests.Identity;

public class RefreshTokenTests
{
    private static readonly DateTimeOffset Now =
        new(2026, 10, 17, 8, 0, 0, TimeSpan.Zero);

    private static readonly TimeSpan Lifetime = TimeSpan.FromDays(7);

    private static readonly Guid UserId = Guid.CreateVersion7();

    [Fact]
    public void Token_is_active_until_the_moment_it_expires()
    {
        var token = RefreshToken.IssueNewFamily(UserId, "hash-1", Now, Lifetime);

        Assert.Equal(Now + Lifetime, token.ExpiresAt);
        Assert.True(token.IsActive(Now));
        Assert.True(token.IsActive(token.ExpiresAt.AddTicks(-1)));
        Assert.False(token.IsActive(token.ExpiresAt));
    }

    [Fact]
    public void Each_sign_in_starts_a_new_family()
    {
        var first = RefreshToken.IssueNewFamily(UserId, "hash-1", Now, Lifetime);
        var second = RefreshToken.IssueNewFamily(UserId, "hash-2", Now, Lifetime);

        Assert.NotEqual(first.FamilyId, second.FamilyId);
    }

    [Fact]
    public void Rotate_issues_a_token_in_the_same_family_and_revokes_the_old_one()
    {
        var current = RefreshToken.IssueNewFamily(UserId, "hash-1", Now, Lifetime);
        var later = Now.AddHours(1);

        var next = current.Rotate("hash-2", later, Lifetime);

        Assert.Equal(current.FamilyId, next.FamilyId);
        Assert.Equal(UserId, next.UserId);
        Assert.Equal(later + Lifetime, next.ExpiresAt);
        Assert.True(next.IsActive(later));

        Assert.True(current.IsRevoked);
        Assert.Equal(RefreshTokenRevocationReason.Rotated, current.RevocationReason);
        Assert.Equal(next.Id, current.ReplacedByTokenId);
    }

    [Fact]
    public void Revoked_token_cannot_be_rotated()
    {
        var token = RefreshToken.IssueNewFamily(UserId, "hash-1", Now, Lifetime);
        token.Revoke(Now, RefreshTokenRevocationReason.LoggedOut);

        Assert.Throws<InvalidOperationException>(
            () => token.Rotate("hash-2", Now, Lifetime));
    }

    [Fact]
    public void Expired_token_cannot_be_rotated()
    {
        var token = RefreshToken.IssueNewFamily(UserId, "hash-1", Now, Lifetime);

        Assert.Throws<InvalidOperationException>(
            () => token.Rotate("hash-2", token.ExpiresAt, Lifetime));
    }

    [Fact]
    public void Revoking_twice_keeps_the_first_reason_and_time()
    {
        var token = RefreshToken.IssueNewFamily(UserId, "hash-1", Now, Lifetime);

        token.Revoke(Now, RefreshTokenRevocationReason.Rotated);
        token.Revoke(Now.AddMinutes(5), RefreshTokenRevocationReason.ReuseDetected);

        Assert.Equal(Now, token.RevokedAt);
        Assert.Equal(RefreshTokenRevocationReason.Rotated, token.RevocationReason);
    }
}