using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.Infrastructure.Identity;

public sealed class UserRepository(AppDbContext dbContext) : IUserRepository
{
    public Task<User?> FindByUserNameAsync(string userName, CancellationToken cancellationToken) =>
        dbContext.Set<User>()
            .SingleOrDefaultAsync(user => user.UserName == userName, cancellationToken);

    public Task<User?> FindByIdAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Set<User>()
            .SingleOrDefaultAsync(user => user.Id == id, cancellationToken);

    public Task<bool> AnyAsync(CancellationToken cancellationToken) =>
        dbContext.Set<User>().AnyAsync(cancellationToken);

    public void Add(User user) => dbContext.Set<User>().Add(user);
}