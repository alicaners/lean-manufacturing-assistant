using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.Domain.Organization;

/// <summary>A plant (fabrika): the top of the organization tree.</summary>
public sealed class Factory : Entity, IFactoryRoot
{
    public const int NameMaxLength = 128;
    public const int CodeMaxLength = 16;

    // Used by EF Core when it reads a plant from the database.
    private Factory()
    {
    }

    private Factory(string name, string code)
    {
        Name = name;
        Code = code;
    }

    public string Name { get; private set; } = null!;

    /// <summary>Short code shown on screens and labels, e.g. "IZM-1". Always upper case.</summary>
    public string Code { get; private set; } = null!;

    public static Factory Create(string name, string code) =>
        new(Guard.Text(name, NameMaxLength, nameof(name)), NormalizeCode(code));

    public void Rename(string name) => Name = Guard.Text(name, NameMaxLength, nameof(name));

    /// <summary>" izm-1 " and "IZM-1" are the same plant code.</summary>
    public static string NormalizeCode(string code) =>
        Guard.Text(code, CodeMaxLength, nameof(code)).ToUpperInvariant();
}