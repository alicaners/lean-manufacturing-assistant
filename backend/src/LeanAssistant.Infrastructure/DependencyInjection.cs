using LeanAssistant.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LeanAssistant.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        string databaseConnectionString,
        string redisConnectionString)
    {
        services.AddSingleton(TimeProvider.System);
        services.AddSingleton<AuditInterceptor>();

        services.AddDbContext<AppDbContext>((serviceProvider, options) =>
            options
                .UseNpgsql(databaseConnectionString)
                .AddInterceptors(serviceProvider.GetRequiredService<AuditInterceptor>()));

        services.AddHealthChecks()
            .AddDbContextCheck<AppDbContext>(name: "database", tags: ["ready"])
            .AddRedis(redisConnectionString, name: "redis", tags: ["ready"]);

        return services;
    }
}