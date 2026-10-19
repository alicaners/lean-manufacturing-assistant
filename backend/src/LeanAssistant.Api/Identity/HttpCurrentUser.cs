using System.Security.Claims;
using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Infrastructure.Identity;
using Microsoft.IdentityModel.JsonWebTokens;

namespace LeanAssistant.Api.Identity;

/// <summary>Reads the current user from the validated access token of the HTTP request.</summary>
public sealed class HttpCurrentUser(IHttpContextAccessor httpContextAccessor) : ICurrentUser
{
    private ClaimsPrincipal? Principal => httpContextAccessor.HttpContext?.User;

    public bool IsAuthenticated => Principal?.Identity?.IsAuthenticated == true;

    public Guid? UserId => ReadGuid(JwtRegisteredClaimNames.Sub);

    public Role? Role =>
        Enum.TryParse<Role>(Principal?.FindFirst(JwtAccessTokenIssuer.RoleClaim)?.Value, out var role)
            ? role
            : null;

    public Guid? FactoryId => ReadGuid(JwtAccessTokenIssuer.FactoryClaim);

    public Guid? LineId => ReadGuid(JwtAccessTokenIssuer.LineClaim);

    private Guid? ReadGuid(string claimType) =>
        Guid.TryParse(Principal?.FindFirst(claimType)?.Value, out var value) ? value : null;
}