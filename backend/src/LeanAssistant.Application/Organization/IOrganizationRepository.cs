using LeanAssistant.Domain.Organization;

namespace LeanAssistant.Application.Organization;

/// <summary>
/// Data access for the organization tree. Every read goes through the plant scope filter,
/// except <see cref="IsFactoryCodeTakenAsync"/>.
/// </summary>
public interface IOrganizationRepository
{
    Task<IReadOnlyList<Factory>> ListFactoriesAsync(CancellationToken cancellationToken);

    Task<Factory?> FindFactoryAsync(Guid id, CancellationToken cancellationToken);

    /// <summary>Checks every plant, not only the caller's: plant codes are unique system-wide.</summary>
    Task<bool> IsFactoryCodeTakenAsync(string code, CancellationToken cancellationToken);

    void Add(Factory factory);

    Task<IReadOnlyList<Department>> ListDepartmentsAsync(Guid factoryId, CancellationToken cancellationToken);

    Task<Department?> FindDepartmentAsync(Guid id, CancellationToken cancellationToken);

    Task<bool> IsDepartmentNameTakenAsync(Guid factoryId, string name, CancellationToken cancellationToken);

    void Add(Department department);

    Task<IReadOnlyList<Line>> ListLinesAsync(Guid departmentId, CancellationToken cancellationToken);

    Task<Line?> FindLineAsync(Guid id, CancellationToken cancellationToken);

    Task<bool> IsLineNameTakenAsync(Guid departmentId, string name, CancellationToken cancellationToken);

    void Add(Line line);

    Task<IReadOnlyList<Machine>> ListMachinesAsync(Guid lineId, CancellationToken cancellationToken);

    Task<Machine?> FindMachineAsync(Guid id, CancellationToken cancellationToken);

    Task<Machine?> FindMachineByQrCodeAsync(string qrCode, CancellationToken cancellationToken);

    Task<bool> IsMachineCodeTakenAsync(Guid factoryId, string code, CancellationToken cancellationToken);

    void Add(Machine machine);
}