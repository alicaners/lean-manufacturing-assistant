using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Organization;

namespace LeanAssistant.UnitTests.Organization;

public class FactoryTreeResponseTests
{
    [Fact]
    public void Each_machine_hangs_under_its_own_line_and_department()
    {
        var plant = Factory.Create("Izmir Plant", "IZM-1");
        var press = Department.Create(plant, "Pres");
        var assembly = Department.Create(plant, "Montaj");
        var pressLine = Line.Create(press, "Pres Hattı 1");
        var assemblyLine = Line.Create(assembly, "Montaj Hattı 1");
        var press4 = Machine.Create(pressLine, "Pres 4", "PRS-04");
        var robot = Machine.Create(assemblyLine, "Robot 1", "RBT-01");

        var tree = FactoryTreeResponse.Build(
            plant, [press, assembly], [pressLine, assemblyLine], [press4, robot]);

        Assert.Equal(plant.Id, tree.Id);
        Assert.Equal(2, tree.Departments.Length);

        var pressNode = Assert.Single(tree.Departments, node => node.Id == press.Id);
        Assert.Equal(press4.Id, Assert.Single(Assert.Single(pressNode.Lines).Machines).Id);

        var assemblyNode = Assert.Single(tree.Departments, node => node.Id == assembly.Id);
        Assert.Equal(robot.Id, Assert.Single(Assert.Single(assemblyNode.Lines).Machines).Id);
    }
}