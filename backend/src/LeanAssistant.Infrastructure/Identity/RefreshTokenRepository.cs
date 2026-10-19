using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.Infrastructure.Identity;

public sealed class RefreshTokenRepository(AppDbContext dbContext) : IRefreshTokenRepository
{
    public Task<RefreshToken?> FindByHashAsync(string tokenHash, CancellationToken cancellationToken) =>
        dbContext.Set<RefreshToken>()
            .SingleOrDefaultAsync(token => token.TokenHash == tokenHash, cancellationToken);

    public async Task<IReadOnlyList<RefreshToken>> ListActiveInFamilyAsync(
        Guid familyId, CancellationToken cancellationToken) =>
        await dbContext.Set<RefreshToken>()
            .Where(token => token.FamilyId == familyId && token.RevokedAt == null)
            .ToListAsync(cancellationToken);

    public async Task<IReadOnlyList<RefreshToken>> ListActiveForUserAsync(
        Guid userId, CancellationToken cancellationToken) =>
        await dbContext.Set<RefreshToken>()
            .Where(token => token.UserId == userId && token.RevokedAt == null)
            .ToListAsync(cancellationToken);

    public void Add(RefreshToken token) => dbContext.Set<RefreshToken>().Add(token);
}