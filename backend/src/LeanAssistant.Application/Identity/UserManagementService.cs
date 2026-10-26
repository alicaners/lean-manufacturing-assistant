using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;
using Microsoft.Extensions.Logging;

namespace LeanAssistant.Application.Identity;

/// <summary>
/// Admin operations on user accounts. The API checks the permission (ManageUsers);
/// this class checks the data scope: a plant admin manages only their own plant.
/// </summary>
/// <remarks>
/// Users outside the caller's plant are hidden by the query filter, so looking one up
/// finds nothing and the API answers 404 without revealing that the user exists.
/// </remarks>
public sealed class UserManagementService(
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IUnitOfWork unitOfWork,
    IPasswordHasher passwordHasher,
    ICurrentUser currentUser,
    IOrganizationDirectory organizationDirectory,
    TimeProvider timeProvider,
    ILogger<UserManagementService> logger)
{
    public async Task<IReadOnlyList<UserResponse>> ListAsync(CancellationToken cancellationToken)
    {
        var visibleUsers = await users.ListAsync(cancellationToken);
        return visibleUsers.Select(UserResponse.From).ToList();
    }

    public async Task<UserResponse?> GetAsync(Guid id, CancellationToken cancellationToken)
    {
        var user = await users.FindByIdAsync(id, cancellationToken);
        return user is null ? null : UserResponse.From(user);
    }

    public async Task<UserManagementResult> CreateAsync(
        CreateUserRequest request, CancellationToken cancellationToken)
    {
        if (!CanAssignPlant(request.FactoryId))
        {
            return UserManagementResult.Failure(UserManagementError.OutsideScope);
        }

        if (!await IsKnownScopeAsync(request.FactoryId, request.LineId, cancellationToken))
        {
            return UserManagementResult.Failure(UserManagementError.UnknownScope);
        }

        var userName = User.NormalizeUserName(request.UserName);
        if (await users.IsUserNameTakenAsync(userName, cancellationToken))
        {
            return UserManagementResult.Failure(UserManagementError.UserNameTaken);
        }

        var user = User.Create(userName, request.FullName, passwordHasher.Hash(request.Password), request.Role);
        user.AssignScope(request.FactoryId, request.LineId);

        // The admin knows this password, so the user must replace it at first sign-in.
        user.RequirePasswordChange();

        users.Add(user);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("User {UserId} was created by {AdminId}", user.Id, currentUser.UserId);
        return UserManagementResult.Success(user);
    }

    public async Task<UserManagementResult> UpdateAccessAsync(
        Guid id, UpdateUserAccessRequest request, CancellationToken cancellationToken)
    {
        if (IsSelf(id))
        {
            return UserManagementResult.Failure(UserManagementError.SelfChange);
        }

        var user = await users.FindByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return UserManagementResult.Failure(UserManagementError.NotFound);
        }

        if (!CanAssignPlant(request.FactoryId))
        {
            return UserManagementResult.Failure(UserManagementError.OutsideScope);
        }

        if (!await IsKnownScopeAsync(request.FactoryId, request.LineId, cancellationToken))
        {
            return UserManagementResult.Failure(UserManagementError.UnknownScope);
        }

        var changed = user.Role != request.Role
            || user.FactoryId != request.FactoryId
            || user.LineId != request.LineId;

        if (changed)
        {
            user.ChangeRole(request.Role);
            user.AssignScope(request.FactoryId, request.LineId);

            // The old tokens carry the old role and plant, so the user must sign in again.
            await RevokeSessionsAsync(user.Id, cancellationToken);
            await unitOfWork.SaveChangesAsync(cancellationToken);

            logger.LogInformation(
                "Access of user {UserId} was changed to {Role} by {AdminId}",
                user.Id, user.Role, currentUser.UserId);
        }

        return UserManagementResult.Success(user);
    }

    public async Task<UserManagementResult> DeactivateAsync(Guid id, CancellationToken cancellationToken)
    {
        if (IsSelf(id))
        {
            return UserManagementResult.Failure(UserManagementError.SelfChange);
        }

        var user = await users.FindByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return UserManagementResult.Failure(UserManagementError.NotFound);
        }

        if (user.IsActive)
        {
            user.Deactivate();
            await RevokeSessionsAsync(user.Id, cancellationToken);
            await unitOfWork.SaveChangesAsync(cancellationToken);

            logger.LogInformation("User {UserId} was deactivated by {AdminId}", user.Id, currentUser.UserId);
        }

        return UserManagementResult.Success();
    }

    public async Task<UserManagementResult> ActivateAsync(Guid id, CancellationToken cancellationToken)
    {
        var user = await users.FindByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return UserManagementResult.Failure(UserManagementError.NotFound);
        }

        if (!user.IsActive)
        {
            user.Activate();
            await unitOfWork.SaveChangesAsync(cancellationToken);

            logger.LogInformation("User {UserId} was activated by {AdminId}", user.Id, currentUser.UserId);
        }

        return UserManagementResult.Success();
    }

    public async Task<UserManagementResult> ResetPasswordAsync(
        Guid id, ResetPasswordRequest request, CancellationToken cancellationToken)
    {
        var user = await users.FindByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return UserManagementResult.Failure(UserManagementError.NotFound);
        }

        user.ReplacePasswordHash(passwordHasher.Hash(request.NewPassword));
        user.RequirePasswordChange();

        // Anyone who knew the old password may still hold a session.
        await RevokeSessionsAsync(user.Id, cancellationToken);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Password of user {UserId} was reset by {AdminId}", user.Id, currentUser.UserId);
        return UserManagementResult.Success();
    }

    /// <summary>Marks the tokens; the caller saves them together with the user change.</summary>
    private async Task RevokeSessionsAsync(Guid userId, CancellationToken cancellationToken)
    {
        var now = timeProvider.GetUtcNow();
        var activeTokens = await refreshTokens.ListActiveForUserAsync(userId, cancellationToken);

        foreach (var token in activeTokens)
        {
            token.Revoke(now, RefreshTokenRevocationReason.UserChanged);
        }
    }

    /// <summary>A system admin (no plant) may use any plant; a plant admin only their own.</summary>
    private bool CanAssignPlant(Guid? factoryId) =>
        currentUser.FactoryId is null || factoryId == currentUser.FactoryId;

    /// <summary>A system admin has no plant, so there is nothing to check.</summary>
    private async Task<bool> IsKnownScopeAsync(
        Guid? factoryId, Guid? lineId, CancellationToken cancellationToken) =>
        factoryId is not { } plantId
        || await organizationDirectory.IsValidScopeAsync(plantId, lineId, cancellationToken);

    private bool IsSelf(Guid id) => currentUser.UserId == id;
}