using System.Net;
using LeanAssistant.Application.Identity;
using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Domain.Organization;
using LeanAssistant.IntegrationTests.Identity;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.IntegrationTests.Organization;

[Collection(ApiCollection.Name)]
public sealed class OrganizationTreeEndpointsTests(ApiFactory factory)
{
    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Fact]
    public async Task Tree_shows_the_whole_plant()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);

        var tree = await GetTreeAsync(plant.Id, admin);

        var line = Assert.Single(Assert.Single(tree.Departments).Lines);
        Assert.Equal(machine.LineId, line.Id);
        Assert.Equal(machine.Id, Assert.Single(line.Machines).Id);
    }

    [Fact]
    public async Task Second_read_comes_from_the_cache()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);
        await GetTreeAsync(plant.Id, admin); // fills the cache

        // Changed directly in the database, behind the API's back:
        // only the cache can still know the old name.
        await using (var dbContext = factory.CreateDbContext())
        {
            await dbContext.Set<Machine>()
                .Where(item => item.Id == machine.Id)
                .ExecuteUpdateAsync(setters => setters.SetProperty(item => item.Name, "Changed behind the API"));
        }

        var tree = await GetTreeAsync(plant.Id, admin);

        Assert.Equal(machine.Name, OnlyMachine(tree).Name);
    }

    [Fact]
    public async Task Changes_through_the_api_refresh_the_tree()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);
        await GetTreeAsync(plant.Id, admin); // fills the cache

        var rename = await _api.SendAsync(
            HttpMethod.Put, $"/api/machines/{machine.Id}", admin, new NameRequest("Pres 4B"));
        Assert.Equal(HttpStatusCode.OK, rename.StatusCode);

        var tree = await GetTreeAsync(plant.Id, admin);

        Assert.Equal("Pres 4B", OnlyMachine(tree).Name);
    }

    [Fact]
    public async Task Cached_tree_of_another_plant_stays_invisible()
    {
        var admin = await _api.LoginAsAdminAsync();
        var ownPlant = await _api.CreatePlantAsync(admin);
        var otherPlant = await _api.CreatePlantAsync(admin);
        await _api.CreateMachineAsync(admin, otherPlant.Id);
        await GetTreeAsync(otherPlant.Id, admin); // the foreign tree is now in the cache
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, ownPlant.Id);

        var response = await _api.SendAsync(
            HttpMethod.Get, $"/api/factories/{otherPlant.Id}/tree", plantAdmin.Tokens);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private async Task<FactoryTreeResponse> GetTreeAsync(Guid plantId, AuthTokens caller)
    {
        var response = await _api.SendAsync(HttpMethod.Get, $"/api/factories/{plantId}/tree", caller);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await IdentityTestClient.ReadAsync<FactoryTreeResponse>(response);
    }

    private static MachineNode OnlyMachine(FactoryTreeResponse tree) =>
        Assert.Single(Assert.Single(Assert.Single(tree.Departments).Lines).Machines);
}