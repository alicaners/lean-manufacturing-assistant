using LeanAssistant.Application.Seeding;

namespace LeanAssistant.Api.Seeding;

public static class SeedingExtensions
{
    /// <summary>
    /// Creates the demo plant and accounts when Seed:DemoData is on.
    /// Off unless configured; meant for development and demos, never for a real plant.
    /// </summary>
    public static async Task SeedDemoDataAsync(this WebApplication app)
    {
        var section = app.Configuration.GetSection("Seed");

        if (!section.GetValue("DemoData", false))
        {
            return;
        }

        var password = section["DemoPassword"];
        if (string.IsNullOrWhiteSpace(password))
        {
            app.Logger.LogWarning(
                "Seed:DemoData is on, but Seed:DemoPassword is not set, so no demo data was created.");
            return;
        }

        await using var scope = app.Services.CreateAsyncScope();
        var seeder = scope.ServiceProvider.GetRequiredService<DemoDataSeeder>();

        await seeder.SeedAsync(password, CancellationToken.None);
    }
}