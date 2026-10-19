namespace LeanAssistant.Domain.Identity;

/// <summary>
/// Which roles hold which permission. Mirrors the matrix in docs/business-rules.md.
/// Data scope (own plant / own line) is checked separately.
/// </summary>
public static class RolePermissions
{
    private static readonly Dictionary<Permission, Role[]> AllowedRoles = new()
    {
        [Permission.ManageUsers] = [Role.Admin],
        [Permission.ManageOrganization] = [Role.Admin],
        [Permission.ReportDowntime] = [Role.Operator, Role.Supervisor],
        [Permission.ResolveDowntime] = [Role.Technician],
        [Permission.CreateSuggestion] = [Role.Operator, Role.Supervisor, Role.Technician],
        [Permission.ReviewSuggestion] = [Role.Supervisor],
        [Permission.PerformAudit] = [Role.Supervisor],
        [Permission.ViewDashboard] = [Role.Manager, Role.Supervisor]
    };

    public static IReadOnlyList<Role> RolesFor(Permission permission) =>
        AllowedRoles.TryGetValue(permission, out var roles) ? roles : [];

    public static bool Allows(Role role, Permission permission) =>
        RolesFor(permission).Contains(role);
}