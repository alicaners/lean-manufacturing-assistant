using LeanAssistant.Domain.Organization;

namespace LeanAssistant.Application.Organization;

public sealed record FactoryResponse(Guid Id, string Name, string Code)
{
    public static FactoryResponse From(Factory factory) =>
        new(factory.Id, factory.Name, factory.Code);
}

public sealed record DepartmentResponse(Guid Id, Guid FactoryId, string Name)
{
    public static DepartmentResponse From(Department department) =>
        new(department.Id, department.FactoryId, department.Name);
}

public sealed record LineResponse(Guid Id, Guid FactoryId, Guid DepartmentId, string Name)
{
    public static LineResponse From(Line line) =>
        new(line.Id, line.FactoryId, line.DepartmentId, line.Name);
}

public sealed record MachineResponse(
    Guid Id, Guid FactoryId, Guid LineId, string Name, string Code, string QrCode)
{
    public static MachineResponse From(Machine machine) =>
        new(machine.Id, machine.FactoryId, machine.LineId, machine.Name, machine.Code, machine.QrCode);
}