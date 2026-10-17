using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;
using Microsoft.Extensions.Logging;

namespace LeanAssistant.Application.Identity;

/// <summary>
/// Creates the first admin account when there are no users at all,
/// so that someone can sign in and create everyone else.
/// Does nothing once any user exists.
/// </summary>
public sealed class AdminBootstrapper(
    IUserRepository users,
    IUnitOfWork unitOfWork,
    IPasswordHasher passwordHasher,
    ILogger<AdminBootstrapper> logger)
{
    public const int MinimumPasswordLength = 12;

    public async Task EnsureAdminAsync(
        string? userName, string? password, CancellationToken cancellationToken)
    {
        if (await users.AnyAsync(cancellationToken))
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(userName) || string.IsNullOrWhiteSpace(password))
        {
            logger.LogWarning(
                "There are no users and no bootstrap admin is configured " +
                "(Bootstrap:AdminUserName, Bootstrap:AdminPassword). Nobody can sign in.");
            return;
        }

        if (password.Length < MinimumPasswordLength)
        {
            throw new InvalidOperationException(
                $"Bootstrap:AdminPassword must be at least {MinimumPasswordLength} characters.");
        }

        var admin = User.Create(userName, "System Administrator", passwordHasher.Hash(password), Role.Admin);

        users.Add(admin);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Bootstrap admin {UserName} was created", admin.UserName);
    }
}