using LeanAssistant.Domain.Organization;

namespace LeanAssistant.UnitTests.Organization;

public class OrganizationTreeTests
{
    private static readonly Factory Plant = Factory.Create("Izmir Plant", "IZM-1");

    [Fact]
    public void Plant_name_and_code_are_cleaned_up()
    {
        var plant = Factory.Create("  Izmir Plant ", " izm-1 ");

        Assert.Equal("Izmir Plant", plant.Name);
        Assert.Equal("IZM-1", plant.Code);
    }

    [Fact]
    public void Empty_name_is_rejected()
    {
        Assert.Throws<ArgumentException>(() => Factory.Create("   ", "IZM-1"));
    }

    [Fact]
    public void Too_long_code_is_rejected()
    {
        var code = new string('X', Factory.CodeMaxLength + 1);

        Assert.Throws<ArgumentException>(() => Factory.Create("Izmir Plant", code));
    }

    [Fact]
    public void Each_level_takes_the_plant_of_its_parent()
    {
        var department = Department.Create(Plant, "Pres");
        var line = Line.Create(department, "Pres Hattı 1");
        var machine = Machine.Create(line, "Pres 4", "prs-04");

        Assert.Equal(Plant.Id, department.FactoryId);
        Assert.Equal(Plant.Id, line.FactoryId);
        Assert.Equal(department.Id, line.DepartmentId);
        Assert.Equal(Plant.Id, machine.FactoryId);
        Assert.Equal(line.Id, machine.LineId);
        Assert.Equal("PRS-04", machine.Code);
    }

    [Fact]
    public void New_machine_gets_a_url_safe_qr_code()
    {
        var machine = NewMachine();

        Assert.Equal(Machine.QrCodeLength, machine.QrCode.Length);
        Assert.Matches("^[A-Za-z0-9_-]+$", machine.QrCode);
    }

    [Fact]
    public void Every_machine_gets_a_different_qr_code()
    {
        var codes = Enumerable.Range(0, 100)
            .Select(_ => NewMachine().QrCode)
            .ToHashSet();

        Assert.Equal(100, codes.Count);
    }

    [Fact]
    public void Regenerating_the_qr_code_replaces_it()
    {
        var machine = NewMachine();
        var oldCode = machine.QrCode;

        machine.RegenerateQrCode();

        Assert.NotEqual(oldCode, machine.QrCode);
    }

    private static Machine NewMachine() =>
        Machine.Create(Line.Create(Department.Create(Plant, "Pres"), "Hat 1"), "Pres 4", "PRS-04");
}