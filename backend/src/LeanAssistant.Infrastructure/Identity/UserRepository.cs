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

    public async Task<IReadOnlyList<User>> ListAsync(CancellationToken cancellationToken) =>
        await dbContext.Set<User>()
            .AsNoTracking()
            .OrderBy(user => user.UserName)
            .ToListAsync(cancellationToken);

    // IgnoreQueryFilters also drops the soft-delete filter, so it is added back by hand.
    // The unique index covers only users that are not deleted, so this matches it exactly.
    public Task<bool> IsUserNameTakenAsync(string userName, CancellationToken cancellationToken) =>
        dbContext.Set<User>()
            .IgnoreQueryFilters()
            .AnyAsync(user => user.UserName == userName && !user.IsDeleted, cancellationToken);

    public void Add(User user) => dbContext.Set<User>().Add(user);
}