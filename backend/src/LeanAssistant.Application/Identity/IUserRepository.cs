using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public interface IUserRepository
{
    /// <param name="userName">Already normalized with <see cref="User.NormalizeUserName"/>.</param>
    Task<User?> FindByUserNameAsync(string userName, CancellationToken cancellationToken);

    Task<User?> FindByIdAsync(Guid id, CancellationToken cancellationToken);

    Task<bool> AnyAsync(CancellationToken cancellationToken);

    
    /// <summary>
    /// Users the current caller may see that match the filter, ordered by user name,
    /// starting right after <paramref name="afterUserName"/>.
    /// </summary>
    Task<IReadOnlyList<User>> ListAsync(
        UserFilter filter, string? afterUserName, int take, CancellationToken cancellationToken);

    /// <summary>
    /// Checks every plant, not only the caller's: user names are unique across the whole system.
    /// </summary>
    /// <param name="userName">Already normalized with <see cref="User.NormalizeUserName"/>.</param>
    Task<bool> IsUserNameTakenAsync(string userName, CancellationToken cancellationToken);

    void Add(User user);
}