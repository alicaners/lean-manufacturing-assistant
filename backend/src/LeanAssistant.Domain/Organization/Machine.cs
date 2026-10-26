using System.Buffers.Text;
using System.Security.Cryptography;
using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.Domain.Organization;

/// <summary>A machine or station on a line. Downtime is always reported against a machine.</summary>
public sealed class Machine : Entity, IFactoryScoped, IAudited
{
    public const int NameMaxLength = 128;
    public const int CodeMaxLength = 32;

    /// <summary>16 random bytes written as Base64Url are always 22 characters.</summary>
    public const int QrCodeLength = 22;

    // Used by EF Core when it reads a machine from the database.
    private Machine()
    {
    }

    private Machine(Guid factoryId, Guid lineId, string name, string code)
    {
        FactoryId = factoryId;
        LineId = lineId;
        Name = name;
        Code = code;
        QrCode = NewQrCode();
    }

    public Guid FactoryId { get; private set; }

    public Guid LineId { get; private set; }

    public string Name { get; private set; } = null!;

    /// <summary>Asset number painted on the machine, e.g. "PRS-04". Unique within a plant.</summary>
    public string Code { get; private set; } = null!;

    /// <summary>
    /// The value printed on the machine's QR label. Random, so one label
    /// tells nothing about the others and the value cannot be guessed.
    /// </summary>
    public string QrCode { get; private set; } = null!;

    Guid? IFactoryScoped.FactoryId => FactoryId;

    public static Machine Create(Line line, string name, string code)
    {
        ArgumentNullException.ThrowIfNull(line);

        return new Machine(
            line.FactoryId,
            line.Id,
            Guard.Text(name, NameMaxLength, nameof(name)),
            NormalizeCode(code));
    }

    public void Rename(string name) => Name = Guard.Text(name, NameMaxLength, nameof(name));

    /// <summary>For a lost or copied label: the old QR code stops working.</summary>
    public void RegenerateQrCode() => QrCode = NewQrCode();

    public static string NormalizeCode(string code) =>
        Guard.Text(code, CodeMaxLength, nameof(code)).ToUpperInvariant();

    private static string NewQrCode()
    {
        Span<byte> bytes = stackalloc byte[16];
        RandomNumberGenerator.Fill(bytes);
        return Base64Url.EncodeToString(bytes);
    }
}