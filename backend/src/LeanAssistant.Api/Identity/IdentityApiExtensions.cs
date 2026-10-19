using System.Text;
using System.Threading.RateLimiting;
using LeanAssistant.Application.Identity;
using LeanAssistant.Infrastructure.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace LeanAssistant.Api.Identity;

public static class IdentityApiExtensions
{
    public const string LoginRateLimitPolicy = "login";

    public static IServiceCollection AddIdentityApi(
        this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<AuthOptions>()
            .Bind(configuration.GetSection(AuthOptions.SectionName))
            .Validate(
                options => options.IsValid(),
                "Auth settings are missing or invalid. Set Auth:SigningKey " +
                $"(at least {AuthOptions.MinimumSigningKeyLength} characters) in User Secrets or as an environment variable.")
            .ValidateOnStart();

        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer();

        // Read the validated AuthOptions instead of the raw configuration.
        services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
            .Configure<IOptions<AuthOptions>>((jwt, auth) =>
            {
                var settings = auth.Value;

                // Keep claim names exactly as they are in the token ("sub", "role").
                jwt.MapInboundClaims = false;

                jwt.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidIssuer = settings.Issuer,
                    ValidAudience = settings.Audience,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SigningKey)),
                    ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                    NameClaimType = JwtRegisteredClaimNames.Sub,
                    RoleClaimType = JwtAccessTokenIssuer.RoleClaim,
                    ClockSkew = TimeSpan.FromSeconds(30)
                };
            });

        // Secure by default: every endpoint needs a signed-in user
        // unless it is explicitly marked with [AllowAnonymous].
        services.AddAuthorizationBuilder()
            .SetFallbackPolicy(new AuthorizationPolicyBuilder()
                .RequireAuthenticatedUser()
                .Build());

                // Sign-in attempts per minute from one IP address. Tests raise it, because
        // every request in the in-memory test server comes from the same "address".
        var loginPermitLimit = configuration.GetValue("RateLimiting:LoginPermitLimit", 5);

        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

            options.AddPolicy(LoginRateLimitPolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = loginPermitLimit,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0
                    }));
        });

        return services;
    }

    /// <summary>Creates the first admin from configuration if there are no users yet.</summary>
    public static async Task EnsureBootstrapAdminAsync(this WebApplication app)
    {
        var section = app.Configuration.GetSection("Bootstrap");

        await using var scope = app.Services.CreateAsyncScope();
        var bootstrapper = scope.ServiceProvider.GetRequiredService<AdminBootstrapper>();

        await bootstrapper.EnsureAdminAsync(
            section["AdminUserName"], section["AdminPassword"], CancellationToken.None);
    }
}