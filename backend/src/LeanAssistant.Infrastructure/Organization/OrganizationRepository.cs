using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Organization;
using LeanAssistant.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.Infrastructure.Organization;

public sealed class OrganizationRepository(AppDbContext dbContext) : IOrganizationRepository
{
    public async Task<IReadOnlyList<Factory>> ListFactoriesAsync(CancellationToken cancellationToken) =>
        await dbContext.Set<Factory>()
            .AsNoTracking()
            .OrderBy(factory => factory.Name)
            .ToListAsync(cancellationToken);

    public Task<Factory?> FindFactoryAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Set<Factory>()
            .SingleOrDefaultAsync(factory => factory.Id == id, cancellationToken);

    // Plant codes are unique across the system, so this check looks past the caller's scope.
    // IgnoreQueryFilters also drops the soft-delete filter, which is added back by hand.
    public Task<bool> IsFactoryCodeTakenAsync(string code, CancellationToken cancellationToken) =>
        dbContext.Set<Factory>()
            .IgnoreQueryFilters()
            .AnyAsync(factory => factory.Code == code && !factory.IsDeleted, cancellationToken);

    public void Add(Factory factory) => dbContext.Set<Factory>().Add(factory);

    public async Task<IReadOnlyList<Department>> ListDepartmentsAsync(
        Guid factoryId, CancellationToken cancellationToken) =>
        await dbContext.Set<Department>()
            .AsNoTracking()
            .Where(department => department.FactoryId == factoryId)
            .OrderBy(department => department.Name)
            .ToListAsync(cancellationToken);

    public Task<Department?> FindDepartmentAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Set<Department>()
            .SingleOrDefaultAsync(department => department.Id == id, cancellationToken);

    public Task<bool> IsDepartmentNameTakenAsync(
        Guid factoryId, string name, CancellationToken cancellationToken) =>
        dbContext.Set<Department>()
            .AnyAsync(department => department.FactoryId == factoryId && department.Name == name, cancellationToken);

    public void Add(Department department) => dbContext.Set<Department>().Add(department);

    public async Task<IReadOnlyList<Line>> ListLinesAsync(Guid departmentId, CancellationToken cancellationToken) =>
        await dbContext.Set<Line>()
            .AsNoTracking()
            .Where(line => line.DepartmentId == departmentId)
            .OrderBy(line => line.Name)
            .ToListAsync(cancellationToken);

    public Task<Line?> FindLineAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Set<Line>()
            .SingleOrDefaultAsync(line => line.Id == id, cancellationToken);

    public Task<bool> IsLineNameTakenAsync(Guid departmentId, string name, CancellationToken cancellationToken) =>
        dbContext.Set<Line>()
            .AnyAsync(line => line.DepartmentId == departmentId && line.Name == name, cancellationToken);

    public void Add(Line line) => dbContext.Set<Line>().Add(line);

    public async Task<IReadOnlyList<Machine>> ListMachinesAsync(Guid lineId, CancellationToken cancellationToken) =>
        await dbContext.Set<Machine>()
            .AsNoTracking()
            .Where(machine => machine.LineId == lineId)
            .OrderBy(machine => machine.Code)
            .ToListAsync(cancellationToken);

    public Task<Machine?> FindMachineAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.Set<Machine>()
            .SingleOrDefaultAsync(machine => machine.Id == id, cancellationToken);

    public Task<Machine?> FindMachineByQrCodeAsync(string qrCode, CancellationToken cancellationToken) =>
        dbContext.Set<Machine>()
            .SingleOrDefaultAsync(machine => machine.QrCode == qrCode, cancellationToken);

    public Task<bool> IsMachineCodeTakenAsync(Guid factoryId, string code, CancellationToken cancellationToken) =>
        dbContext.Set<Machine>()
            .AnyAsync(machine => machine.FactoryId == factoryId && machine.Code == code, cancellationToken);

    public void Add(Machine machine) => dbContext.Set<Machine>().Add(machine);
}