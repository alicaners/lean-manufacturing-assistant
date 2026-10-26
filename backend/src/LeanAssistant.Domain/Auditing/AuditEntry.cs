namespace LeanAssistant.Domain.Auditing;

public enum AuditAction
{
    Created,
    Updated,
    Deleted
}

/// <summary>
/// One recorded change: who changed which record, when, and what the values were.
/// Written automatically on every save; never changed or deleted afterwards.
/// </summary>
public sealed class AuditEntry
{
    public const int EntityTypeMaxLength = 64;

    // Used by EF Core when it reads an entry from the database.
    private AuditEntry()
    {
    }

    public AuditEntry(
        DateTimeOffset occurredAt,
        Guid? userId,
        string entityType,
        Guid entityId,
        AuditAction action,
        Guid? factoryId,
        string changes)
    {
        OccurredAt = occurredAt;
        UserId = userId;
        EntityType = entityType;
        EntityId = entityId;
        Action = action;
        FactoryId = factoryId;
        Changes = changes;
    }

    public Guid Id { get; private set; } = Guid.CreateVersion7();

    public DateTimeOffset OccurredAt { get; private set; }

    /// <summary>Who made the change. Empty when nobody was signed in (startup, sign-in).</summary>
    public Guid? UserId { get; private set; }

    /// <summary>The kind of record, e.g. "Machine".</summary>
    public string EntityType { get; private set; } = null!;

    public Guid EntityId { get; private set; }

    public AuditAction Action { get; private set; }

    /// <summary>The plant of the changed record, so a plant can later be shown only its own history.</summary>
    public Guid? FactoryId { get; private set; }

    /// <summary>
    /// JSON, e.g. <c>{ "Name": { "old": "Pres 4", "new": "Pres 4B" } }</c>.
    /// Hashes and other secrets are written as "***".
    /// </summary>
    public string Changes { get; private set; } = null!;
}