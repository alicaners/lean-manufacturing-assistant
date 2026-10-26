using System.Net;
using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Domain.Organization;
using LeanAssistant.IntegrationTests.Identity;

namespace LeanAssistant.IntegrationTests.Organization;

[Collection(ApiCollection.Name)]
public sealed class OrganizationEndpointsTests(ApiFactory factory)
{
    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Fact]
    public async Task Organization_requires_a_token()
    {
        var response = await _api.Http.GetAsync("/api/factories");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task System_admin_builds_a_plant_tree()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);

        var machine = await _api.CreateMachineAsync(admin, plant.Id);

        Assert.Equal(plant.Id, machine.FactoryId);
        Assert.Equal(Machine.QrCodeLength, machine.QrCode.Length);

        var list = await _api.SendAsync(HttpMethod.Get, $"/api/lines/{machine.LineId}/machines", admin);
        var machines = await IdentityTestClient.ReadAsync<MachineResponse[]>(list);
        Assert.Contains(machines, item => item.Id == machine.Id);
    }

    [Fact]
    public async Task Plant_codes_are_unique()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);

        var response = await _api.SendAsync(
            HttpMethod.Post, "/api/factories", admin,
            new CreateFactoryRequest("Copy", plant.Code.ToLowerInvariant()));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Machine_codes_are_unique_within_a_plant()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);

        var response = await _api.SendAsync(
            HttpMethod.Post, $"/api/lines/{machine.LineId}/machines", admin,
            new CreateMachineRequest("Another Press", machine.Code));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Plant_admin_cannot_create_plants()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, plant.Id);

        var response = await _api.SendAsync(
            HttpMethod.Post, "/api/factories", plantAdmin.Tokens,
            new CreateFactoryRequest("My Own Plant", OrganizationTestData.NewCode("P")));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Operator_can_read_but_not_change_the_organization()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);
        var operatorUser = await _api.CreateSignedInUserAsync(admin, Role.Operator, plant.Id);

        var read = await _api.SendAsync(HttpMethod.Get, $"/api/machines/{machine.Id}", operatorUser.Tokens);
        var rename = await _api.SendAsync(
            HttpMethod.Put, $"/api/machines/{machine.Id}", operatorUser.Tokens, new NameRequest("Renamed"));

        Assert.Equal(HttpStatusCode.OK, read.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, rename.StatusCode);
    }

    [Fact]
    public async Task Scanning_a_label_finds_the_machine()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);
        var operatorUser = await _api.CreateSignedInUserAsync(admin, Role.Operator, plant.Id);

        var response = await _api.SendAsync(
            HttpMethod.Get, $"/api/machines/by-qr/{machine.QrCode}", operatorUser.Tokens);

        var found = await IdentityTestClient.ReadAsync<MachineResponse>(response);
        Assert.Equal(machine.Id, found.Id);
    }

    [Fact]
    public async Task Regenerated_qr_code_replaces_the_old_one()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);

        var regenerate = await _api.SendAsync(HttpMethod.Post, $"/api/machines/{machine.Id}/regenerate-qr", admin);
        var updated = await IdentityTestClient.ReadAsync<MachineResponse>(regenerate);

        Assert.NotEqual(machine.QrCode, updated.QrCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await _api.SendAsync(HttpMethod.Get, $"/api/machines/by-qr/{machine.QrCode}", admin)).StatusCode);
        Assert.Equal(
            HttpStatusCode.OK,
            (await _api.SendAsync(HttpMethod.Get, $"/api/machines/by-qr/{updated.QrCode}", admin)).StatusCode);
    }

    [Fact]
    public async Task Machine_of_another_plant_is_invisible()
    {
        var admin = await _api.LoginAsAdminAsync();
        var ownPlant = await _api.CreatePlantAsync(admin);
        var otherPlant = await _api.CreatePlantAsync(admin);
        var foreignMachine = await _api.CreateMachineAsync(admin, otherPlant.Id);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, ownPlant.Id);

        // Every way of reaching the foreign machine must look as if it did not exist.
        (HttpMethod Method, string Url, object? Body)[] attempts =
        [
            (HttpMethod.Get, $"/api/machines/{foreignMachine.Id}", null),
            (HttpMethod.Put, $"/api/machines/{foreignMachine.Id}", new NameRequest("Taken over")),
            (HttpMethod.Post, $"/api/machines/{foreignMachine.Id}/regenerate-qr", null),
            (HttpMethod.Get, $"/api/machines/by-qr/{foreignMachine.QrCode}", null),
            (HttpMethod.Get, $"/api/lines/{foreignMachine.LineId}/machines", null),
            (HttpMethod.Post, $"/api/lines/{foreignMachine.LineId}/machines", new CreateMachineRequest("Planted", "X-1")),
            (HttpMethod.Get, $"/api/factories/{otherPlant.Id}", null)
        ];

        foreach (var (method, url, body) in attempts)
        {
            var response = await _api.SendAsync(method, url, plantAdmin.Tokens, body);
            Assert.True(
                response.StatusCode == HttpStatusCode.NotFound,
                $"{method} {url} answered {(int)response.StatusCode} instead of 404.");
        }

        var list = await _api.SendAsync(HttpMethod.Get, "/api/factories", plantAdmin.Tokens);
        var visiblePlants = await IdentityTestClient.ReadAsync<FactoryResponse[]>(list);
        Assert.Equal(ownPlant.Id, Assert.Single(visiblePlants).Id);
    }
}