using System.Text;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace LeanAssistant.Infrastructure.Identity;

/// <summary>
/// Creates JWT access tokens signed with HMAC-SHA256.
/// A JWT is signed, not encrypted: anyone can read its contents,
/// so it only carries what the API needs to know (who, which role, which plant and line).
/// </summary>
public sealed class JwtAccessTokenIssuer(
    IOptions<AuthOptions> options,
    TimeProvider timeProvider) : IAccessTokenIssuer
{
    public const string RoleClaim = "role";
    public const string FactoryClaim = "factory";
    public const string LineClaim = "line";

    private readonly JsonWebTokenHandler _handler = new();

    public AccessToken Issue(User user)
    {
        var settings = options.Value;
        var now = timeProvider.GetUtcNow();
        var expiresAt = now + settings.AccessTokenLifetime;

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SigningKey));

        var claims = new Dictionary<string, object>
        {
            [JwtRegisteredClaimNames.Sub] = user.Id.ToString(),
            [JwtRegisteredClaimNames.Jti] = Guid.NewGuid().ToString(),
            [RoleClaim] = user.Role.ToString()
        };

        if (user.FactoryId is { } factoryId)
        {
            claims[FactoryClaim] = factoryId.ToString();
        }

        if (user.LineId is { } lineId)
        {
            claims[LineClaim] = lineId.ToString();
        }

        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = settings.Issuer,
            Audience = settings.Audience,
            IssuedAt = now.UtcDateTime,
            NotBefore = now.UtcDateTime,
            Expires = expiresAt.UtcDateTime,
            SigningCredentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256),
            Claims = claims
        };

        return new AccessToken(_handler.CreateToken(descriptor), expiresAt);
    }
}