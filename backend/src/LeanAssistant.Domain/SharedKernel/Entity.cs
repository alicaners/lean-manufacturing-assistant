namespace LeanAssistant.Domain.SharedKernel;

/// <summary>
/// Base class for all entities: identity, audit timestamps,
/// soft delete and optimistic concurrency.
/// </summary>
public abstract class Entity
{
    public Guid Id { get; protected init; } = Guid.CreateVersion7();

    public DateTimeOffset CreatedAt { get; private set; }
    public DateTimeOffset UpdatedAt { get; private set; }

    public bool IsDeleted { get; private set; }
    public DateTimeOffset? DeletedAt { get; private set; }

    /// <summary>
    /// Concurrency token. Managed by the database; never set in code.
    /// </summary>
    public uint Version { get; private set; }

    public void MarkCreated(DateTimeOffset now)
    {
        EnsureUtc(now);
        CreatedAt = now;
        UpdatedAt = now;
    }

    public void MarkUpdated(DateTimeOffset now)
    {
        EnsureUtc(now);
        UpdatedAt = now;
    }

    public void MarkDeleted(DateTimeOffset now)
    {
        EnsureUtc(now);
        if (IsDeleted)
        {
            return;
        }

        IsDeleted = true;
        DeletedAt = now;
        UpdatedAt = now;
    }

    private static void EnsureUtc(DateTimeOffset value)
    {
        if (value.Offset != TimeSpan.Zero)
        {
            throw new ArgumentException("Timestamps must be in UTC.", nameof(value));
        }
    }
}