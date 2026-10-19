using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Abstractions;

/// <summary>The signed-in user of the current request, as stated in the access token.</summary>
public interface ICurrentUser
{
    bool IsAuthenticated { get; }

    Guid? UserId { get; }

    Role? Role { get; }

    Guid? FactoryId { get; }

    Guid? LineId { get; }
}