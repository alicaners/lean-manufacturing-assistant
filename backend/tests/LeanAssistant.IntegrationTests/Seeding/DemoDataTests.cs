using LeanAssistant.Application.Organization;
using LeanAssistant.Application.Seeding;
using LeanAssistant.Domain.Organization;
using LeanAssistant.IntegrationTests.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LeanAssistant.IntegrationTests.Seeding;

[Collection(ApiCollection.Name)]
public sealed class DemoDataTests(ApiFactory factory)
{
    private const string DemoPassword = "Integration-Demo-Password";

    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Theory]
    [InlineData("demo.admin")]
    [InlineData("demo.manager")]
    [InlineData("demo.supervisor")]
    [InlineData("demo.technician")]
    [InlineData("demo.operator")]
    public async Task Every_demo_account_can_sign_in_right_away(string userName)
    {
        await SeedAsync();

        var tokens = await _api.LoginAsync(userName, DemoPassword);

        Assert.False(tokens.MustChangePassword);
    }

    [Fact]
    public async Task Demo_plant_has_a_complete_tree()
    {
        await SeedAsync();
        var tokens = await _api.LoginAsync("demo.operator", DemoPassword);

        // The operator sees exactly one plant: the demo plant.
        var list = await _api.SendAsync(HttpMethod.Get, "/api/factories", tokens);
        var plant = Assert.Single(await IdentityTestClient.ReadAsync<FactoryResponse[]>(list));
        Assert.Equal(DemoDataSeeder.FactoryCode, plant.Code);

        var response = await _api.SendAsync(HttpMethod.Get, $"/api/factories/{plant.Id}/tree", tokens);
        var tree = await IdentityTestClient.ReadAsync<FactoryTreeResponse>(response);

        Assert.Equal(3, tree.Departments.Length);
        Assert.All(tree.Departments, department => Assert.NotEmpty(department.Lines));
        Assert.All(tree.Departments.SelectMany(department => department.Lines), line => Assert.NotEmpty(line.Machines));
    }

    [Fact]
    public async Task Seeding_again_changes_nothing()
    {
        await SeedAsync();
        await SeedAsync();

        await using var dbContext = factory.CreateDbContext();
        var demoPlants = await dbContext.Set<Factory>()
            .CountAsync(plant => plant.Code == DemoDataSeeder.FactoryCode);

        Assert.Equal(1, demoPlants);
    }

    private async Task SeedAsync()
    {
        await using var scope = factory.Services.CreateAsyncScope();
        var seeder = scope.ServiceProvider.GetRequiredService<DemoDataSeeder>();

        await seeder.SeedAsync(DemoPassword, CancellationToken.None);
    }
}