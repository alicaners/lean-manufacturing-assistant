using System.Text.Json;
using System.Text.Json.Serialization;
using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Auditing;
using LeanAssistant.Domain.SharedKernel;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace LeanAssistant.Infrastructure.Persistence;

/// <summary>
/// Runs just before every save:
/// <list type="number">
/// <item>sets the CreatedAt / UpdatedAt timestamps,</item>
/// <item>turns deletes into soft deletes,</item>
/// <item>writes an <see cref="AuditEntry"/> for every change of an <see cref="IAudited"/> entity,
/// in the same transaction as the change itself.</item>
/// </list>
/// </summary>
public sealed class AuditInterceptor(TimeProvider timeProvider, ICurrentUser currentUser) : SaveChangesInterceptor
{
    /// <summary>Written instead of a secret value; the entry only shows that it changed.</summary>
    public const string MaskedValue = "***";

    // Bookkeeping columns change on every save and say nothing about the business change.
    private static readonly HashSet<string> IgnoredProperties =
    [
        nameof(Entity.Id),
        nameof(Entity.CreatedAt),
        nameof(Entity.UpdatedAt),
        nameof(Entity.IsDeleted),
        nameof(Entity.DeletedAt),
        nameof(Entity.Version)
    ];

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() }
    };

    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData,
        InterceptionResult<int> result)
    {
        ApplyAuditRules(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        ApplyAuditRules(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void ApplyAuditRules(DbContext? context)
    {
        if (context is null)
        {
            return;
        }

        var now = timeProvider.GetUtcNow();

        // Collected first and added at the end: adding entries to the context
        // while looping over its tracked entries would change the list being read.
        var auditEntries = new List<AuditEntry>();

        foreach (var entry in context.ChangeTracker.Entries<Entity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.MarkCreated(now);
                    break;

                case EntityState.Modified:
                    entry.Entity.MarkUpdated(now);
                    break;

                case EntityState.Deleted:
                    entry.State = EntityState.Modified;
                    entry.Entity.MarkDeleted(now);
                    break;
            }

            if (entry.Entity is IAudited && CreateAuditEntry(entry, now) is { } auditEntry)
            {
                auditEntries.Add(auditEntry);
            }
        }

        context.Set<AuditEntry>().AddRange(auditEntries);
    }

    private AuditEntry? CreateAuditEntry(EntityEntry<Entity> entry, DateTimeOffset now)
    {
        if (ActionOf(entry) is not { } action)
        {
            return null;
        }

        var changes = new Dictionary<string, AuditChange>();

        foreach (var property in entry.Properties)
        {
            var name = property.Metadata.Name;
            if (IgnoredProperties.Contains(name))
            {
                continue;
            }

            if (action == AuditAction.Created)
            {
                changes[name] = new AuditChange(null, Display(name, property.CurrentValue));
            }
            else if (action == AuditAction.Updated
                && property.IsModified
                && !Equals(property.OriginalValue, property.CurrentValue))
            {
                changes[name] = new AuditChange(
                    Display(name, property.OriginalValue),
                    Display(name, property.CurrentValue));
            }
        }

        // Only bookkeeping columns changed: nothing worth recording.
        if (action == AuditAction.Updated && changes.Count == 0)
        {
            return null;
        }

        return new AuditEntry(
            now,
            currentUser.UserId,
            entry.Metadata.ClrType.Name,
            entry.Entity.Id,
            action,
            FactoryOf(entry.Entity),
            JsonSerializer.Serialize(changes, JsonOptions));
    }

    private static AuditAction? ActionOf(EntityEntry<Entity> entry) => entry.State switch
    {
        EntityState.Added => AuditAction.Created,

        // A soft delete arrives here as a modification that switches IsDeleted on.
        EntityState.Modified when entry.Entity.IsDeleted
            && !(bool)entry.Property(nameof(Entity.IsDeleted)).OriginalValue! => AuditAction.Deleted,

        EntityState.Modified => AuditAction.Updated,
        _ => null
    };

    // Hashes (password, token) never enter the audit log.
    private static object? Display(string propertyName, object? value) =>
        propertyName.EndsWith("Hash", StringComparison.Ordinal) ? MaskedValue : value;

    private static Guid? FactoryOf(Entity entity) => entity switch
    {
        IFactoryScoped scoped => scoped.FactoryId,
        IFactoryRoot => entity.Id,
        _ => null
    };

    private sealed record AuditChange(object? Old, object? New);
}