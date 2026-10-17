using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LeanAssistant.Application.Identity;

/// <summary>
/// Sign-in, token refresh and sign-out.
/// Every failure returns <c>null</c> without saying why, so a caller cannot learn
/// whether a user name exists or which part of the request was wrong.
/// </summary>
public sealed class AuthService(
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IUnitOfWork unitOfWork,
    IPasswordHasher passwordHasher,
    IRefreshTokenGenerator refreshTokenGenerator,
    IAccessTokenIssuer accessTokenIssuer,
    IOptions<AuthOptions> options,
    TimeProvider timeProvider,
    ILogger<AuthService> logger)
{
    public async Task<AuthTokens?> LoginAsync(
        string userName, string password, CancellationToken cancellationToken)
    {
        var user = await users.FindByUserNameAsync(User.NormalizeUserName(userName), cancellationToken);

        if (user is null)
        {
            // Do the same expensive work as a real check, so the response time
            // does not reveal whether the user name exists.
            passwordHasher.Hash(password);
            return null;
        }

        var check = passwordHasher.Verify(user.PasswordHash, password);
        if (check == PasswordCheckResult.Failed || !user.IsActive)
        {
            logger.LogWarning("Failed sign-in for user {UserId}", user.Id);
            return null;
        }

        if (check == PasswordCheckResult.SuccessRehashNeeded)
        {
            user.ReplacePasswordHash(passwordHasher.Hash(password));
        }

        var now = timeProvider.GetUtcNow();
        var generated = refreshTokenGenerator.Generate();
        var refreshToken = RefreshToken.IssueNewFamily(
            user.Id, generated.TokenHash, now, options.Value.RefreshTokenLifetime);

        refreshTokens.Add(refreshToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return CreateResponse(user, generated.Token, refreshToken);
    }

    public async Task<AuthTokens?> RefreshAsync(string refreshToken, CancellationToken cancellationToken)
    {
        var stored = await refreshTokens.FindByHashAsync(
            refreshTokenGenerator.Hash(refreshToken), cancellationToken);

        if (stored is null)
        {
            return null;
        }

        var now = timeProvider.GetUtcNow();

        if (stored.IsRevoked)
        {
            // This token was already used or revoked, yet someone presented it again.
            // We cannot tell the real user from a thief, so the whole sign-in is closed.
            await RevokeFamilyAsync(stored.FamilyId, now, cancellationToken);

            logger.LogWarning(
                "Refresh token reuse detected for user {UserId}; family {FamilyId} was revoked",
                stored.UserId, stored.FamilyId);

            return null;
        }

        if (stored.IsExpired(now))
        {
            return null;
        }

        var user = await users.FindByIdAsync(stored.UserId, cancellationToken);
        if (user is null || !user.IsActive)
        {
            return null;
        }

        var generated = refreshTokenGenerator.Generate();
        var next = stored.Rotate(generated.TokenHash, now, options.Value.RefreshTokenLifetime);

        refreshTokens.Add(next);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return CreateResponse(user, generated.Token, next);
    }

    /// <summary>Revokes the token. Unknown or already revoked tokens are ignored.</summary>
    public async Task LogoutAsync(string refreshToken, CancellationToken cancellationToken)
    {
        var stored = await refreshTokens.FindByHashAsync(
            refreshTokenGenerator.Hash(refreshToken), cancellationToken);

        if (stored is null || stored.IsRevoked)
        {
            return;
        }

        stored.Revoke(timeProvider.GetUtcNow(), RefreshTokenRevocationReason.LoggedOut);
        await unitOfWork.SaveChangesAsync(cancellationToken);
    }

    private async Task RevokeFamilyAsync(
        Guid familyId, DateTimeOffset now, CancellationToken cancellationToken)
    {
        var family = await refreshTokens.ListActiveInFamilyAsync(familyId, cancellationToken);

        foreach (var token in family)
        {
            token.Revoke(now, RefreshTokenRevocationReason.ReuseDetected);
        }

        await unitOfWork.SaveChangesAsync(cancellationToken);
    }

    private AuthTokens CreateResponse(User user, string refreshToken, RefreshToken stored)
    {
        var accessToken = accessTokenIssuer.Issue(user);

        return new AuthTokens(
            accessToken.Token,
            accessToken.ExpiresAt,
            refreshToken,
            stored.ExpiresAt);
    }
}