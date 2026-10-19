using LeanAssistant.Domain.Identity;

namespace LeanAssistant.UnitTests.Identity;

public class RolePermissionsTests
{
    [Fact]
    public void Every_permission_is_held_by_at_least_one_role()
    {
        foreach (var permission in Enum.GetValues<Permission>())
        {
            Assert.NotEmpty(RolePermissions.RolesFor(permission));
        }
    }

    [Theory]
    [InlineData(Role.Admin, Permission.ManageUsers, true)]
    [InlineData(Role.Supervisor, Permission.ManageUsers, false)]
    [InlineData(Role.Operator, Permission.ReportDowntime, true)]
    [InlineData(Role.Technician, Permission.ReportDowntime, false)]
    [InlineData(Role.Technician, Permission.ResolveDowntime, true)]
    [InlineData(Role.Operator, Permission.ResolveDowntime, false)]
    [InlineData(Role.Supervisor, Permission.ReviewSuggestion, true)]
    [InlineData(Role.Operator, Permission.ReviewSuggestion, false)]
    [InlineData(Role.Manager, Permission.ViewDashboard, true)]
    [InlineData(Role.Operator, Permission.ViewDashboard, false)]
    [InlineData(Role.Admin, Permission.ReportDowntime, false)]
    public void Matches_the_business_rules(Role role, Permission permission, bool allowed)
    {
        Assert.Equal(allowed, RolePermissions.Allows(role, permission));
    }
}