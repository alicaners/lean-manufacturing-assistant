using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

/// <summary>What the API shows about a user. Never includes the password hash.</summary>
public sealed record UserResponse(
    Guid Id,
    string UserName,
    string FullName,
    Role Role,
    bool IsActive,
    Guid? FactoryId,
    Guid? LineId,
    DateTimeOffset CreatedAt)
{
    public static UserResponse From(User user) => new(
        user.Id,
        user.UserName,
        user.FullName,
        user.Role,
        user.IsActive,
        user.FactoryId,
        user.LineId,
        user.CreatedAt);
}