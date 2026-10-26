using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.Domain.Organization;

/// <summary>A production line (hat) inside a department.</summary>
public sealed class Line : Entity, IFactoryScoped, IAudited
{
    public const int NameMaxLength = 128;

    // Used by EF Core when it reads a line from the database.
    private Line()
    {
    }

    private Line(Guid factoryId, Guid departmentId, string name)
    {
        FactoryId = factoryId;
        DepartmentId = departmentId;
        Name = name;
    }

    /// <summary>Copied from the department, so plant-scoped queries need no join.</summary>
    public Guid FactoryId { get; private set; }

    public Guid DepartmentId { get; private set; }

    public string Name { get; private set; } = null!;

    Guid? IFactoryScoped.FactoryId => FactoryId;

    public static Line Create(Department department, string name)
    {
        ArgumentNullException.ThrowIfNull(department);
        return new Line(department.FactoryId, department.Id, Guard.Text(name, NameMaxLength, nameof(name)));
    }

    public void Rename(string name) => Name = Guard.Text(name, NameMaxLength, nameof(name));
}