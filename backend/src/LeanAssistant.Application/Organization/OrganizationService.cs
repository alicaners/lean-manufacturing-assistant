using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Organization;
using Microsoft.Extensions.Logging;

namespace LeanAssistant.Application.Organization;

/// <summary>
/// Reads and changes the organization tree.
/// Records outside the caller's plant are hidden by the query filter, so looking one up
/// finds nothing and the API answers 404. A child is always created under a parent that
/// was looked up first, so it can only be added inside the caller's own plant.
/// </summary>
public sealed class OrganizationService(
    IOrganizationRepository organization,
    IUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    ILogger<OrganizationService> logger)
{
    // ---------- Plants ----------

    public async Task<FactoryResponse[]> ListFactoriesAsync(CancellationToken cancellationToken)
    {
        var factories = await organization.ListFactoriesAsync(cancellationToken);
        return factories.Select(FactoryResponse.From).ToArray();
    }

    public async Task<OrganizationResult<FactoryResponse>> GetFactoryAsync(
        Guid id, CancellationToken cancellationToken)
    {
        var factory = await organization.FindFactoryAsync(id, cancellationToken);
        if (factory is null)
        {
            return OrganizationError.NotFound;
        }

        return FactoryResponse.From(factory);
    }

    public async Task<OrganizationResult<FactoryResponse>> CreateFactoryAsync(
        CreateFactoryRequest request, CancellationToken cancellationToken)
    {
        // A plant admin works inside one plant; only a system admin opens new plants.
        if (currentUser.FactoryId is not null)
        {
            return OrganizationError.SystemAdminOnly;
        }

        var code = Factory.NormalizeCode(request.Code);
        if (await organization.IsFactoryCodeTakenAsync(code, cancellationToken))
        {
            return OrganizationError.DuplicateCode;
        }

        var factory = Factory.Create(request.Name, code);
        organization.Add(factory);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Plant {FactoryId} was created by {UserId}", factory.Id, currentUser.UserId);
        return FactoryResponse.From(factory);
    }

    public async Task<OrganizationResult<FactoryResponse>> RenameFactoryAsync(
        Guid id, NameRequest request, CancellationToken cancellationToken)
    {
        var factory = await organization.FindFactoryAsync(id, cancellationToken);
        if (factory is null)
        {
            return OrganizationError.NotFound;
        }

        factory.Rename(request.Name);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return FactoryResponse.From(factory);
    }

    // ---------- Departments ----------

    public async Task<OrganizationResult<DepartmentResponse[]>> ListDepartmentsAsync(
        Guid factoryId, CancellationToken cancellationToken)
    {
        // An unknown or foreign plant answers 404, not an empty list.
        if (await organization.FindFactoryAsync(factoryId, cancellationToken) is null)
        {
            return OrganizationError.NotFound;
        }

        var departments = await organization.ListDepartmentsAsync(factoryId, cancellationToken);
        return departments.Select(DepartmentResponse.From).ToArray();
    }

    public async Task<OrganizationResult<DepartmentResponse>> GetDepartmentAsync(
        Guid id, CancellationToken cancellationToken)
    {
        var department = await organization.FindDepartmentAsync(id, cancellationToken);
        if (department is null)
        {
            return OrganizationError.NotFound;
        }

        return DepartmentResponse.From(department);
    }

    public async Task<OrganizationResult<DepartmentResponse>> CreateDepartmentAsync(
        Guid factoryId, NameRequest request, CancellationToken cancellationToken)
    {
        var factory = await organization.FindFactoryAsync(factoryId, cancellationToken);
        if (factory is null)
        {
            return OrganizationError.NotFound;
        }

        var name = request.Name.Trim();
        if (await organization.IsDepartmentNameTakenAsync(factory.Id, name, cancellationToken))
        {
            return OrganizationError.DuplicateName;
        }

        var department = Department.Create(factory, name);
        organization.Add(department);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return DepartmentResponse.From(department);
    }

    public async Task<OrganizationResult<DepartmentResponse>> RenameDepartmentAsync(
        Guid id, NameRequest request, CancellationToken cancellationToken)
    {
        var department = await organization.FindDepartmentAsync(id, cancellationToken);
        if (department is null)
        {
            return OrganizationError.NotFound;
        }

        var name = request.Name.Trim();
        if (name != department.Name
            && await organization.IsDepartmentNameTakenAsync(department.FactoryId, name, cancellationToken))
        {
            return OrganizationError.DuplicateName;
        }

        department.Rename(name);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return DepartmentResponse.From(department);
    }

    // ---------- Lines ----------

    public async Task<OrganizationResult<LineResponse[]>> ListLinesAsync(
        Guid departmentId, CancellationToken cancellationToken)
    {
        if (await organization.FindDepartmentAsync(departmentId, cancellationToken) is null)
        {
            return OrganizationError.NotFound;
        }

        var lines = await organization.ListLinesAsync(departmentId, cancellationToken);
        return lines.Select(LineResponse.From).ToArray();
    }

    public async Task<OrganizationResult<LineResponse>> GetLineAsync(
        Guid id, CancellationToken cancellationToken)
    {
        var line = await organization.FindLineAsync(id, cancellationToken);
        if (line is null)
        {
            return OrganizationError.NotFound;
        }

        return LineResponse.From(line);
    }

    public async Task<OrganizationResult<LineResponse>> CreateLineAsync(
        Guid departmentId, NameRequest request, CancellationToken cancellationToken)
    {
        var department = await organization.FindDepartmentAsync(departmentId, cancellationToken);
        if (department is null)
        {
            return OrganizationError.NotFound;
        }

        var name = request.Name.Trim();
        if (await organization.IsLineNameTakenAsync(department.Id, name, cancellationToken))
        {
            return OrganizationError.DuplicateName;
        }

        var line = Line.Create(department, name);
        organization.Add(line);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return LineResponse.From(line);
    }

    public async Task<OrganizationResult<LineResponse>> RenameLineAsync(
        Guid id, NameRequest request, CancellationToken cancellationToken)
    {
        var line = await organization.FindLineAsync(id, cancellationToken);
        if (line is null)
        {
            return OrganizationError.NotFound;
        }

        var name = request.Name.Trim();
        if (name != line.Name
            && await organization.IsLineNameTakenAsync(line.DepartmentId, name, cancellationToken))
        {
            return OrganizationError.DuplicateName;
        }

        line.Rename(name);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return LineResponse.From(line);
    }

    // ---------- Machines ----------

    public async Task<OrganizationResult<MachineResponse[]>> ListMachinesAsync(
        Guid lineId, CancellationToken cancellationToken)
    {
        if (await organization.FindLineAsync(lineId, cancellationToken) is null)
        {
            return OrganizationError.NotFound;
        }

        var machines = await organization.ListMachinesAsync(lineId, cancellationToken);
        return machines.Select(MachineResponse.From).ToArray();
    }

    public async Task<OrganizationResult<MachineResponse>> GetMachineAsync(
        Guid id, CancellationToken cancellationToken)
    {
        var machine = await organization.FindMachineAsync(id, cancellationToken);
        if (machine is null)
        {
            return OrganizationError.NotFound;
        }

        return MachineResponse.From(machine);
    }

    /// <summary>A label of another plant answers 404 like any other foreign record.</summary>
    public async Task<OrganizationResult<MachineResponse>> FindMachineByQrCodeAsync(
        string qrCode, CancellationToken cancellationToken)
    {
        var machine = await organization.FindMachineByQrCodeAsync(qrCode, cancellationToken);
        if (machine is null)
        {
            return OrganizationError.NotFound;
        }

        return MachineResponse.From(machine);
    }

    public async Task<OrganizationResult<MachineResponse>> CreateMachineAsync(
        Guid lineId, CreateMachineRequest request, CancellationToken cancellationToken)
    {
        var line = await organization.FindLineAsync(lineId, cancellationToken);
        if (line is null)
        {
            return OrganizationError.NotFound;
        }

        var code = Machine.NormalizeCode(request.Code);
        if (await organization.IsMachineCodeTakenAsync(line.FactoryId, code, cancellationToken))
        {
            return OrganizationError.DuplicateCode;
        }

        var machine = Machine.Create(line, request.Name, code);
        organization.Add(machine);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Machine {MachineId} was created by {UserId}", machine.Id, currentUser.UserId);
        return MachineResponse.From(machine);
    }

    public async Task<OrganizationResult<MachineResponse>> RenameMachineAsync(
        Guid id, NameRequest request, CancellationToken cancellationToken)
    {
        var machine = await organization.FindMachineAsync(id, cancellationToken);
        if (machine is null)
        {
            return OrganizationError.NotFound;
        }

        machine.Rename(request.Name);
        await unitOfWork.SaveChangesAsync(cancellationToken);

        return MachineResponse.From(machine);
    }

    public async Task<OrganizationResult<MachineResponse>> RegenerateQrCodeAsync(
        Guid id, CancellationToken cancellationToken)
    {
        var machine = await organization.FindMachineAsync(id, cancellationToken);
        if (machine is null)
        {
            return OrganizationError.NotFound;
        }

        machine.RegenerateQrCode();
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation(
            "QR code of machine {MachineId} was replaced by {UserId}", machine.Id, currentUser.UserId);
        return MachineResponse.From(machine);
    }
}