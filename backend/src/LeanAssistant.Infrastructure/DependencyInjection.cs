using LeanAssistant.Application.Abstractions;
using LeanAssistant.Application.Identity;
using LeanAssistant.Infrastructure.Identity;
using LeanAssistant.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using LeanAssistant.Application.Organization;
using LeanAssistant.Infrastructure.Organization;

namespace LeanAssistant.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        string databaseConnectionString,
        string redisConnectionString)
    {
        services.AddSingleton(TimeProvider.System);
                // Scoped, not singleton: it needs the signed-in user of the current request.
        services.AddScoped<AuditInterceptor>();

        services.AddDbContext<AppDbContext>((serviceProvider, options) =>
            options
                .UseNpgsql(databaseConnectionString)
                .AddInterceptors(serviceProvider.GetRequiredService<AuditInterceptor>()));

        // The same AppDbContext instance of the request saves the changes.
        services.AddScoped<IUnitOfWork>(serviceProvider =>
            serviceProvider.GetRequiredService<AppDbContext>());

        services.AddHealthChecks()
            .AddDbContextCheck<AppDbContext>(name: "database", tags: ["ready"])
            .AddRedis(redisConnectionString, name: "redis", tags: ["ready"]);

        // Identity: security services. All are stateless, so one instance is shared.
        services.AddSingleton<IPasswordHasher, IdentityPasswordHasher>();
        services.AddSingleton<IRefreshTokenGenerator, RefreshTokenGenerator>();
        services.AddSingleton<IAccessTokenIssuer, JwtAccessTokenIssuer>();

        // Identity: data access, one instance per request like the DbContext.
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
        
        // Organization: data access, one instance per request like the DbContext.
        services.AddScoped<IOrganizationRepository, OrganizationRepository>();
        services.AddScoped<IOrganizationDirectory, OrganizationDirectory>(); 
        
        // Organization: the tree cache lives in Redis, shared by every API instance.
        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = redisConnectionString;
            options.InstanceName = "lean:";
        });
        services.AddSingleton<IOrganizationTreeCache, RedisOrganizationTreeCache>();

        return services;
    }
}