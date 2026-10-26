namespace LeanAssistant.Domain.SharedKernel;

/// <summary>
/// The plant itself. Its scope is its own <see cref="Entity.Id"/>: a user bound to a plant
/// sees only that plant, just like <see cref="IFactoryScoped"/> records.
/// </summary>
public interface IFactoryRoot;