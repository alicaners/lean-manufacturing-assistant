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

        public async Task<IReadOnlyList<User>> ListAsync(
        UserFilter filter, string? afterUserName, int take, CancellationToken cancellationToken)
    {
        var query = dbContext.Set<User>().AsNoTracking();

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var pattern = ContainsPattern(filter.Search.Trim());
            query = query.Where(user =>
                EF.Functions.ILike(user.UserName, pattern, LikeEscapeCharacter)
                || EF.Functions.ILike(user.FullName, pattern, LikeEscapeCharacter));
        }

        if (filter.Role is { } role)
        {
            query = query.Where(user => user.Role == role);
        }

        if (filter.IsActive is { } isActive)
        {
            query = query.Where(user => user.IsActive == isActive);
        }

        // Keyset paging: continue right after the last user of the previous page.
        // The unique index on UserName lets the database jump straight there.
        if (afterUserName is not null)
        {
            query = query.Where(user => string.Compare(user.UserName, afterUserName) > 0);
        }

        return await query
            .OrderBy(user => user.UserName)
            .Take(take)
            .ToListAsync(cancellationToken);
    }

    private const string LikeEscapeCharacter = @"\";

    // "50%" must search for the text "50%", not for "50 followed by anything".
    private static string ContainsPattern(string text) =>
        "%" + text.Replace(@"\", @"\\").Replace("%", @"\%").Replace("_", @"\_") + "%";

    // IgnoreQueryFilters also drops the soft-delete filter, so it is added back by hand.
    // The unique index covers only users that are not deleted, so this matches it exactly.
    public Task<bool> IsUserNameTakenAsync(string userName, CancellationToken cancellationToken) =>
        dbContext.Set<User>()
            .IgnoreQueryFilters()
            .AnyAsync(user => user.UserName == userName && !user.IsDeleted, cancellationToken);

    public void Add(User user) => dbContext.Set<User>().Add(user);
}