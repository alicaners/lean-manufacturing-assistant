using System.Net;
using LeanAssistant.Application.Abstractions;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using LeanAssistant.IntegrationTests.Organization;

namespace LeanAssistant.IntegrationTests.Identity;

[Collection(ApiCollection.Name)]
public sealed class UserListEndpointsTests(ApiFactory factory)
{
    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Fact]
    public async Task Pages_cover_every_user_exactly_once()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, plant.Id);

        // Six users in a fresh plant: the plant admin and five operators.
        var expected = new List<Guid> { plantAdmin.User.Id };
        for (var i = 0; i < 5; i++)
        {
            expected.Add((await _api.CreateUserAsync(admin, Role.Operator, plant.Id)).Id);
        }

        var seen = new List<Guid>();
        string? cursor = null;
        var pages = 0;

        do
        {
            var url = cursor is null ? "/api/users?limit=2" : $"/api/users?limit=2&cursor={cursor}";
            var page = await ReadPageAsync(url, plantAdmin.Tokens);

            Assert.True(page.Items.Length <= 2);
            seen.AddRange(page.Items.Select(user => user.Id));
            cursor = page.NextCursor;
            pages++;
        }
        while (cursor is not null && pages < 10);

        Assert.Equal(expected.Order(), seen.Order());
        Assert.Equal(3, pages);
    }

    [Fact]
    public async Task Search_finds_a_part_of_the_user_name_in_any_case()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var target = await _api.CreateUserAsync(admin, Role.Operator, plant.Id);
        await _api.CreateUserAsync(admin, Role.Operator, plant.Id);

        var part = target.UserName[^8..].ToUpperInvariant();
        var page = await ReadPageAsync($"/api/users?search={part}", admin);

        Assert.Equal(target.Id, Assert.Single(page.Items).Id);
    }

    [Fact]
    public async Task Filters_by_role_and_by_status()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, plant.Id);
        await _api.CreateUserAsync(admin, Role.Operator, plant.Id);
        var technician = await _api.CreateUserAsync(admin, Role.Technician, plant.Id);
        var leaver = await _api.CreateUserAsync(admin, Role.Operator, plant.Id);
        await _api.SendAsync(HttpMethod.Post, $"/api/users/{leaver.Id}/deactivate", admin);

        var technicians = await ReadPageAsync("/api/users?role=Technician", plantAdmin.Tokens);
        var inactive = await ReadPageAsync("/api/users?isActive=false", plantAdmin.Tokens);

        Assert.Equal(technician.Id, Assert.Single(technicians.Items).Id);
        Assert.Equal(leaver.Id, Assert.Single(inactive.Items).Id);
    }

    [Theory]
    [InlineData("/api/users?cursor=not-a-valid-cursor")]
    [InlineData("/api/users?limit=0")]
    [InlineData("/api/users?limit=101")]
    public async Task Invalid_paging_parameters_are_rejected(string url)
    {
        var admin = await _api.LoginAsAdminAsync();

        var response = await _api.SendAsync(HttpMethod.Get, url, admin);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<CursorPage<UserResponse>> ReadPageAsync(string url, AuthTokens caller)
    {
        var response = await _api.SendAsync(HttpMethod.Get, url, caller);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await IdentityTestClient.ReadAsync<CursorPage<UserResponse>>(response);
    }
}