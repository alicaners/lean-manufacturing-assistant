using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.Domain.Organization;

/// <summary>A department (bölüm) of a plant, e.g. "Pres" or "Montaj".</summary>
public sealed class Department : Entity, IFactoryScoped, IAudited
{
    public const int NameMaxLength = 128;

    // Used by EF Core when it reads a department from the database.
    private Department()
    {
    }

    private Department(Guid factoryId, string name)
    {
        FactoryId = factoryId;
        Name = name;
    }

    public Guid FactoryId { get; private set; }

    public string Name { get; private set; } = null!;

    // Every department belongs to a plant, so its scope is never empty.
    Guid? IFactoryScoped.FactoryId => FactoryId;

    /// <summary>
    /// Takes the plant itself, not its id: the caller must have loaded it first,
    /// and that read only finds plants inside the caller's own scope.
    /// </summary>
    public static Department Create(Factory factory, string name)
    {
        ArgumentNullException.ThrowIfNull(factory);
        return new Department(factory.Id, Guard.Text(name, NameMaxLength, nameof(name)));
    }

    public void Rename(string name) => Name = Guard.Text(name, NameMaxLength, nameof(name));
}