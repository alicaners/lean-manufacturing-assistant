using LeanAssistant.Domain.Organization;

namespace LeanAssistant.Application.Organization;

/// <summary>A whole plant in one response: departments, their lines and the machines on them.</summary>
public sealed record FactoryTreeResponse(Guid Id, string Name, string Code, DepartmentNode[] Departments)
{
    /// <summary>Hangs every line under its department and every machine under its line.</summary>
    public static FactoryTreeResponse Build(
        Factory factory,
        IEnumerable<Department> departments,
        IEnumerable<Line> lines,
        IEnumerable<Machine> machines)
    {
        var linesByDepartment = lines.ToLookup(line => line.DepartmentId);
        var machinesByLine = machines.ToLookup(machine => machine.LineId);

        var departmentNodes = departments
            .Select(department => new DepartmentNode(
                department.Id,
                department.Name,
                linesByDepartment[department.Id]
                    .Select(line => new LineNode(
                        line.Id,
                        line.Name,
                        machinesByLine[line.Id]
                            .Select(machine => new MachineNode(machine.Id, machine.Name, machine.Code))
                            .ToArray()))
                    .ToArray()))
            .ToArray();

        return new FactoryTreeResponse(factory.Id, factory.Name, factory.Code, departmentNodes);
    }
}

public sealed record DepartmentNode(Guid Id, string Name, LineNode[] Lines);

public sealed record LineNode(Guid Id, string Name, MachineNode[] Machines);

public sealed record MachineNode(Guid Id, string Name, string Code);