using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public interface IUserRepository
{
    /// <param name="userName">Already normalized with <see cref="User.NormalizeUserName"/>.</param>
    Task<User?> FindByUserNameAsync(string userName, CancellationToken cancellationToken);

    Task<User?> FindByIdAsync(Guid id, CancellationToken cancellationToken);

    Task<bool> AnyAsync(CancellationToken cancellationToken);

    void Add(User user);
}