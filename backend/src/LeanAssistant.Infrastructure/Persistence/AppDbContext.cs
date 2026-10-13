using System.Linq.Expressions;
using LeanAssistant.Domain.SharedKernel;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.Infrastructure.Persistence;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);

        foreach (var entityType in modelBuilder.Model.GetEntityTypes())
        {
            var isRootEntity = typeof(Entity).IsAssignableFrom(entityType.ClrType)
                && entityType.BaseType is null;

            if (!isRootEntity)
            {
                continue;
            }

            var builder = modelBuilder.Entity(entityType.ClrType);

            // Optimistic concurrency: PostgreSQL's xmin system column.
            builder.Property(nameof(Entity.Version)).IsRowVersion();

            // Soft delete: hide deleted rows from every query (e => !e.IsDeleted).
            var parameter = Expression.Parameter(entityType.ClrType, "e");
            var isDeleted = Expression.Property(parameter, nameof(Entity.IsDeleted));
            var filter = Expression.Lambda(Expression.Not(isDeleted), parameter);
            builder.HasQueryFilter(filter);
        }
    }
}