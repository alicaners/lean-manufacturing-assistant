using System.Linq.Expressions;
using System.Reflection;
using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Domain.SharedKernel;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.Infrastructure.Persistence;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options, ICurrentUser currentUser)
    : DbContext(options), IUnitOfWork
{
    private static readonly PropertyInfo ScopeAppliesProperty =
        typeof(AppDbContext).GetProperty(nameof(ScopeApplies), BindingFlags.Instance | BindingFlags.NonPublic)!;

    private static readonly PropertyInfo ScopeFactoryIdProperty =
        typeof(AppDbContext).GetProperty(nameof(ScopeFactoryId), BindingFlags.Instance | BindingFlags.NonPublic)!;

    /// <summary>
    /// True when the request belongs to a signed-in user limited to one plant.
    /// Not limited: startup, background jobs, anonymous endpoints (sign-in, refresh)
    /// and an admin without a plant (system-wide admin).
    /// </summary>
    private bool ScopeApplies =>
        currentUser.IsAuthenticated
        && !(currentUser.Role == Role.Admin && currentUser.FactoryId is null);

    private Guid? ScopeFactoryId => currentUser.FactoryId;

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

            builder.HasQueryFilter(BuildQueryFilter(entityType.ClrType));
        }
    }

    /// <summary>
    /// e => !e.IsDeleted
    ///      && (for plant-scoped entities) (!ScopeApplies || (ScopeFactoryId != null && e.FactoryId == ScopeFactoryId))
    /// </summary>
    private LambdaExpression BuildQueryFilter(Type entityType)
    {
        var entity = Expression.Parameter(entityType, "e");

        // Soft delete: hide deleted rows from every query.
        Expression filter = Expression.Not(Expression.Property(entity, nameof(Entity.IsDeleted)));

        if (typeof(IFactoryScoped).IsAssignableFrom(entityType))
        {
            filter = Expression.AndAlso(filter, BuildFactoryScope(entity));
        }

        return Expression.Lambda(filter, entity);
    }

    private Expression BuildFactoryScope(ParameterExpression entity)
    {
        // "this" is replaced by EF Core with the DbContext running the query,
        // so the values are read from the current request's user every time.
        var context = Expression.Constant(this);
        var scopeApplies = Expression.Property(context, ScopeAppliesProperty);
        var scopeFactoryId = Expression.Property(context, ScopeFactoryIdProperty);

        Expression entityFactoryId = Expression.Property(entity, nameof(IFactoryScoped.FactoryId));
        if (entityFactoryId.Type != typeof(Guid?))
        {
            entityFactoryId = Expression.Convert(entityFactoryId, typeof(Guid?));
        }

        return Expression.OrElse(
            Expression.Not(scopeApplies),
            Expression.AndAlso(
                Expression.NotEqual(scopeFactoryId, Expression.Constant(null, typeof(Guid?))),
                Expression.Equal(entityFactoryId, scopeFactoryId)));
    }
}