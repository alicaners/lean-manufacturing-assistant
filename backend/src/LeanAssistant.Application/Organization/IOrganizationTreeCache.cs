namespace LeanAssistant.Application.Organization;

/// <summary>
/// Keeps each plant's organization tree ready to serve.
/// A cache problem must never fail a request; implementations fall back to "not cached".
/// </summary>
public interface IOrganizationTreeCache
{
    Task<FactoryTreeResponse?> GetAsync(Guid factoryId, CancellationToken cancellationToken);

    Task SetAsync(FactoryTreeResponse tree, CancellationToken cancellationToken);

    /// <summary>Called after any change inside the plant; the next read builds a fresh tree.</summary>
    Task InvalidateAsync(Guid factoryId, CancellationToken cancellationToken);
}