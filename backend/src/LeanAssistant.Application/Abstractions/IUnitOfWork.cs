namespace LeanAssistant.Application.Abstractions;

/// <summary>Saves every change made in the current request in one database transaction.</summary>
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}