using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

/// <summary>Creates short-lived access tokens (JWT) for signed-in users.</summary>
public interface IAccessTokenIssuer
{
    AccessToken Issue(User user);
}

public sealed record AccessToken(string Token, DateTimeOffset ExpiresAt);