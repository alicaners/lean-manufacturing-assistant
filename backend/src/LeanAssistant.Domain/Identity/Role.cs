namespace LeanAssistant.Domain.Identity;

/// <summary>
/// What a user is allowed to do. One role per user.
/// Stored in the database by name, so the order of the values can change safely.
/// </summary>
public enum Role
{
    Operator,
    Supervisor,
    Technician,
    Manager,
    Admin
}