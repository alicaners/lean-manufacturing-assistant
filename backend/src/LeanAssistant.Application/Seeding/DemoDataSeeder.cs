using LeanAssistant.Application.Abstractions;
using LeanAssistant.Application.Identity;
using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Domain.Organization;
using Microsoft.Extensions.Logging;

namespace LeanAssistant.Application.Seeding;

/// <summary>
/// Creates a demo plant with departments, lines and machines, and one ready-to-use
/// account per role. For development and demos only; never enabled for a real plant.
/// Safe to run on every start: once the demo plant exists, it does nothing.
/// </summary>
/// <remarks>
/// It spans the Identity and Organization modules on purpose: it is a setup tool
/// outside both modules, not part of either one's business logic.
/// </remarks>
public sealed class DemoDataSeeder(
    IOrganizationRepository organization,
    IUserRepository users,
    IPasswordHasher passwordHasher,
    IUnitOfWork unitOfWork,
    ILogger<DemoDataSeeder> logger)
{
    public const string FactoryCode = "DEMO-IZM";

    public async Task SeedAsync(string password, CancellationToken cancellationToken)
    {
        if (password.Length < PasswordRules.MinimumLength)
        {
            throw new InvalidOperationException(
                $"Seed:DemoPassword must be at least {PasswordRules.MinimumLength} characters.");
        }

        if (await organization.IsFactoryCodeTakenAsync(FactoryCode, cancellationToken))
        {
            return;
        }

        var plant = Factory.Create("Demo Fabrika İzmir", FactoryCode);
        organization.Add(plant);

        var press = AddDepartment(plant, "Pres");
        var assembly = AddDepartment(plant, "Montaj");
        var paint = AddDepartment(plant, "Boya");

        var pressLine1 = AddLine(press, "Pres Hattı 1");
        var pressLine2 = AddLine(press, "Pres Hattı 2");
        var assemblyLine = AddLine(assembly, "Montaj Hattı 1");
        var paintLine = AddLine(paint, "Boya Hattı 1");

        AddMachine(pressLine1, "Pres 1", "PRS-01");
        AddMachine(pressLine1, "Pres 2", "PRS-02");
        AddMachine(pressLine1, "Pres 3", "PRS-03");
        AddMachine(pressLine2, "Pres 4", "PRS-04");
        AddMachine(pressLine2, "Pres 5", "PRS-05");
        AddMachine(assemblyLine, "Kaynak Robotu 1", "KYN-01");
        AddMachine(assemblyLine, "Vidalama İstasyonu 1", "VDL-01");
        AddMachine(paintLine, "Boya Kabini 1", "BOY-01");
        AddMachine(paintLine, "Kurutma Fırını 1", "FRN-01");

        // Hashing is slow on purpose, so the same hash is shared by every demo account.
        var passwordHash = passwordHasher.Hash(password);

        await AddUserAsync("demo.admin", "Demo Admin", Role.Admin, plant.Id, null, passwordHash, cancellationToken);
        await AddUserAsync("demo.manager", "Demo Yönetici", Role.Manager, plant.Id, null, passwordHash, cancellationToken);
        await AddUserAsync("demo.supervisor", "Demo Şef", Role.Supervisor, plant.Id, pressLine1.Id, passwordHash, cancellationToken);
        await AddUserAsync("demo.technician", "Demo Teknisyen", Role.Technician, plant.Id, null, passwordHash, cancellationToken);
        await AddUserAsync("demo.operator", "Demo Operatör", Role.Operator, plant.Id, pressLine1.Id, passwordHash, cancellationToken);

        // One save, one transaction: the demo data appears completely or not at all.
        await unitOfWork.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Demo plant {FactoryCode} and its demo accounts were created", FactoryCode);
    }

    private Department AddDepartment(Factory plant, string name)
    {
        var department = Department.Create(plant, name);
        organization.Add(department);
        return department;
    }

    private Line AddLine(Department department, string name)
    {
        var line = Line.Create(department, name);
        organization.Add(line);
        return line;
    }

    private void AddMachine(Line line, string name, string code) =>
        organization.Add(Machine.Create(line, name, code));

    private async Task AddUserAsync(
        string userName,
        string fullName,
        Role role,
        Guid factoryId,
        Guid? lineId,
        string passwordHash,
        CancellationToken cancellationToken)
    {
        if (await users.IsUserNameTakenAsync(userName, cancellationToken))
        {
            logger.LogWarning("Demo account {UserName} was skipped: the user name is already taken", userName);
            return;
        }

        var user = User.Create(userName, fullName, passwordHash, role);
        user.AssignScope(factoryId, lineId);
        users.Add(user);
    }
}