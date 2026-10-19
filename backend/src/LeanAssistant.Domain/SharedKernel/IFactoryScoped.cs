namespace LeanAssistant.Domain.SharedKernel;

/// <summary>
/// An entity that belongs to one plant. Every query on it is automatically
/// limited to the signed-in user's plant (see AppDbContext).
/// </summary>
public interface IFactoryScoped
{
    Guid? FactoryId { get; }
}