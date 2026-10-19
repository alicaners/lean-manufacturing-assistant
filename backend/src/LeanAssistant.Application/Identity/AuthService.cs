using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LeanAssistant.Application.Identity;

/// <summary>
/// Sign-in, token refresh, sign-out and password change.
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

        var tokens = StartNewSession(user, timeProvider.GetUtcNow());
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return tokens;
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
            // A token that was already exchanged is presented again. We cannot tell
            // the real user from a thief, so the whole sign-in is closed.
            // Tokens revoked for other reasons (sign-out, admin change) are just rejected.
            if (stored.RevocationReason == RefreshTokenRevocationReason.Rotated)
            {
                await RevokeFamilyAsync(stored.FamilyId, now, cancellationToken);

                logger.LogWarning(
                    "Refresh token reuse detected for user {UserId}; family {FamilyId} was revoked",
                    stored.UserId, stored.FamilyId);
            }

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

    /// <summary>
    /// Replaces the password of a signed-in user. Every session of the user is closed and
    /// a new one is returned, so only the device that changed the password stays signed in.
    /// Returns <c>null</c> when the current password is wrong.
    /// </summary>
    public async Task<AuthTokens?> ChangePasswordAsync(
        Guid userId, string currentPassword, string newPassword, CancellationToken cancellationToken)
    {
        var user = await users.FindByIdAsync(userId, cancellationToken);
        if (user is null || !user.IsActive)
        {
            return null;
        }

        if (passwordHasher.Verify(user.PasswordHash, currentPassword) == PasswordCheckResult.Failed)
        {
            logger.LogWarning("Failed password change for user {UserId}", user.Id);
            return null;
        }

        user.ChangePassword(passwordHasher.Hash(newPassword));

        var now = timeProvider.GetUtcNow();
        var activeTokens = await refreshTokens.ListActiveForUserAsync(user.Id, cancellationToken);
        foreach (var token in activeTokens)
        {
            token.Revoke(now, RefreshTokenRevocationReason.PasswordChanged);
        }

        var tokens = StartNewSession(user, now);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("User {UserId} changed their password", user.Id);
        return tokens;
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

    /// <summary>Starts a new token family. The caller saves it.</summary>
    private AuthTokens StartNewSession(User user, DateTimeOffset now)
    {
        var generated = refreshTokenGenerator.Generate();
        var refreshToken = RefreshToken.IssueNewFamily(
            user.Id, generated.TokenHash, now, options.Value.RefreshTokenLifetime);

        refreshTokens.Add(refreshToken);

        return CreateResponse(user, generated.Token, refreshToken);
    }

    private AuthTokens CreateResponse(User user, string refreshToken, RefreshToken stored)
    {
        var accessToken = accessTokenIssuer.Issue(user);

        return new AuthTokens(
            accessToken.Token,
            accessToken.ExpiresAt,
            refreshToken,
            stored.ExpiresAt,
            user.MustChangePassword);
    }
}