using LeanAssistant.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Testcontainers.PostgreSql;
using LeanAssistant.Application.Abstractions;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.IntegrationTests;

/// <summary>
/// Runs the real API in memory against a throw-away PostgreSQL container.
/// One instance is shared by every test in the <see cref="ApiCollection"/>.
/// </summary>
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    public const string AdminUserName = "admin";
    public const string AdminPassword = "Integration-Test-Admin-Password";

    private readonly PostgreSqlContainer _database =
        new PostgreSqlBuilder("postgres:17-alpine").Build();

    public async Task InitializeAsync()
    {
        await _database.StartAsync();

        // The schema must exist before the app starts, because startup
        // already queries the Users table (bootstrap admin).
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(_database.GetConnectionString())
            .Options;
                await using (var dbContext = new AppDbContext(options, new NoCurrentUser()))
        {
            await dbContext.Database.MigrateAsync();
        }

        // Program.cs reads these while it builds the app, so they are given as
        // environment variables, which override every other configuration source.
        SetSetting("ConnectionStrings__Database", _database.GetConnectionString());
        SetSetting("ConnectionStrings__Redis", "localhost:6399,abortConnect=false");
        SetSetting("Auth__SigningKey", "integration-test-signing-key-that-is-long-enough");
        SetSetting("Bootstrap__AdminUserName", AdminUserName);
        SetSetting("Bootstrap__AdminPassword", AdminPassword);
        SetSetting("RateLimiting__LoginPermitLimit", "1000");
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Not "Development": User Secrets and Swagger stay off, like on a server.
        builder.UseEnvironment("Testing");
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        await base.DisposeAsync();
        await _database.DisposeAsync();
    }

    private static void SetSetting(string name, string value) =>
        Environment.SetEnvironmentVariable(name, value);

        
    /// <summary>Migrations run before the app starts, outside any request.</summary>
    private sealed class NoCurrentUser : ICurrentUser
    {
        public bool IsAuthenticated => false;

        public Guid? UserId => null;

        public Role? Role => null;

        public Guid? FactoryId => null;

        public Guid? LineId => null;
    }
}