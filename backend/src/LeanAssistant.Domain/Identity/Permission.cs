namespace LeanAssistant.Domain.Identity;

/// <summary>
/// Things a user may be allowed to do. Endpoints ask for a permission,
/// never for a role, so the role-to-permission table can change in one place.
/// </summary>
public enum Permission
{
    ManageUsers,
    ManageOrganization,
    ReportDowntime,
    ResolveDowntime,
    CreateSuggestion,
    ReviewSuggestion,
    PerformAudit,
    ViewDashboard
}