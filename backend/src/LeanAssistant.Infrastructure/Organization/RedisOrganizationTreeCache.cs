using System.Text.Json;
using LeanAssistant.Application.Organization;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;

namespace LeanAssistant.Infrastructure.Organization;

/// <summary>
/// Keeps each plant's tree in Redis, shared by every API instance.
/// A cache problem never fails the request: a failed read counts as "not cached"
/// and the tree is built from the database instead.
/// </summary>
public sealed class RedisOrganizationTreeCache(
    IDistributedCache cache,
    ILogger<RedisOrganizationTreeCache> logger) : IOrganizationTreeCache
{
    /// <summary>Upper bound for a stale tree, should an invalidation ever be missed.</summary>
    public static readonly TimeSpan TimeToLive = TimeSpan.FromMinutes(10);

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<FactoryTreeResponse?> GetAsync(Guid factoryId, CancellationToken cancellationToken)
    {
        try
        {
            var bytes = await cache.GetAsync(Key(factoryId), cancellationToken);
            return bytes is null ? null : JsonSerializer.Deserialize<FactoryTreeResponse>(bytes, JsonOptions);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(exception, "Reading the tree of plant {FactoryId} from the cache failed", factoryId);
            return null;
        }
    }

    public async Task SetAsync(FactoryTreeResponse tree, CancellationToken cancellationToken)
    {
        try
        {
            await cache.SetAsync(
                Key(tree.Id),
                JsonSerializer.SerializeToUtf8Bytes(tree, JsonOptions),
                new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeToLive },
                cancellationToken);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(exception, "Writing the tree of plant {FactoryId} to the cache failed", tree.Id);
        }
    }

    public async Task InvalidateAsync(Guid factoryId, CancellationToken cancellationToken)
    {
        try
        {
            await cache.RemoveAsync(Key(factoryId), cancellationToken);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            // Worse than a failed read: the old tree stays until it expires.
            logger.LogError(exception, "Removing the tree of plant {FactoryId} from the cache failed", factoryId);
        }
    }

    // "v1": if the shape of the tree ever changes, the version changes too,
    // and entries written by older code are simply never read again.
    private static string Key(Guid factoryId) => $"org-tree:v1:{factoryId}";
}