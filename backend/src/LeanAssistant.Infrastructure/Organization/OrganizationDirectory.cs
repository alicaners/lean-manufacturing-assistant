using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Organization;
using LeanAssistant.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.Infrastructure.Organization;

public sealed class OrganizationDirectory(AppDbContext dbContext) : IOrganizationDirectory
{
    public async Task<bool> IsValidScopeAsync(
        Guid factoryId, Guid? lineId, CancellationToken cancellationToken)
    {
        if (lineId is null)
        {
            return await dbContext.Set<Factory>()
                .AnyAsync(factory => factory.Id == factoryId, cancellationToken);
        }

        // A line always belongs to an existing plant, so one query answers both questions.
        return await dbContext.Set<Line>()
            .AnyAsync(line => line.Id == lineId && line.FactoryId == factoryId, cancellationToken);
    }
}