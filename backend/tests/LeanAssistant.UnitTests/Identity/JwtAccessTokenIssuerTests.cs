using System.Text;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Infrastructure.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace LeanAssistant.UnitTests.Identity;

public class JwtAccessTokenIssuerTests
{
    private static readonly DateTimeOffset Now =
        new(2026, 10, 17, 8, 0, 0, TimeSpan.Zero);

    private static readonly AuthOptions Settings = new()
    {
        Issuer = "test-issuer",
        Audience = "test-audience",
        SigningKey = "test-signing-key-that-is-long-enough-1234",
        AccessTokenLifetime = TimeSpan.FromMinutes(15)
    };

    private static readonly User Supervisor =
        User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Supervisor);

    [Fact]
    public void Token_carries_user_id_role_issuer_audience_and_expiry()
    {
        var accessToken = CreateIssuer().Issue(Supervisor);

        var jwt = new JsonWebToken(accessToken.Token);

        Assert.Equal(Supervisor.Id.ToString(), jwt.Subject);
        Assert.Equal("Supervisor", jwt.GetClaim(JwtAccessTokenIssuer.RoleClaim).Value);
        Assert.Equal(Settings.Issuer, jwt.Issuer);
        Assert.Contains(Settings.Audience, jwt.Audiences);
        Assert.Equal(Now.AddMinutes(15), accessToken.ExpiresAt);
        Assert.Equal(Now.AddMinutes(15).UtcDateTime, jwt.ValidTo);
    }

    [Fact]
    public async Task Token_is_valid_with_the_signing_key()
    {
        var token = CreateIssuer().Issue(Supervisor).Token;

        var result = await ValidateAsync(token, Settings.SigningKey);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task Token_is_rejected_with_another_key()
    {
        var token = CreateIssuer().Issue(Supervisor).Token;

        var result = await ValidateAsync(token, "a-different-key-that-is-also-long-enough");

        Assert.False(result.IsValid);
    }

    private static JwtAccessTokenIssuer CreateIssuer() =>
        new(Options.Create(Settings), new FixedTimeProvider(Now));

    private static Task<TokenValidationResult> ValidateAsync(string token, string key) =>
        new JsonWebTokenHandler().ValidateTokenAsync(token, new TokenValidationParameters
        {
            ValidIssuer = Settings.Issuer,
            ValidAudience = Settings.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)),
            // The token was issued at a fixed time in the past; this test is about the signature.
            ValidateLifetime = false
        });

    private sealed class FixedTimeProvider(DateTimeOffset now) : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => now;
    }
}