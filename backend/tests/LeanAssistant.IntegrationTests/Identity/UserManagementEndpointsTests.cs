using System.Net;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using LeanAssistant.IntegrationTests.Organization;
using LeanAssistant.Application.Abstractions;

namespace LeanAssistant.IntegrationTests.Identity;

[Collection(ApiCollection.Name)]
public sealed class UserManagementEndpointsTests(ApiFactory factory)
{
    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Fact]
    public async Task Users_endpoint_requires_a_token()
    {
        var response = await _api.Http.GetAsync("/api/users");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Operator_cannot_manage_users()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        // Signed in with a chosen password, so a 403 here comes from the role, not the lock.
        var operatorUser = await _api.CreateSignedInUserAsync(admin, Role.Operator, plant.Id);

        var response = await _api.SendAsync(HttpMethod.Get, "/api/users", operatorUser.Tokens);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_creates_a_user_who_can_sign_in()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);

        var user = await _api.CreateUserAsync(admin, Role.Operator, plant.Id);

        Assert.Equal(Role.Operator, user.Role);
        Assert.Equal(plant.Id, user.FactoryId);
        Assert.True(user.IsActive);
        Assert.True(user.MustChangePassword);

        var tokens = await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);
        Assert.True(tokens.MustChangePassword);
    }

    [Fact]
    public async Task Every_role_except_admin_needs_a_plant()
    {
        var admin = await _api.LoginAsAdminAsync();
        var request = new CreateUserRequest(
            IdentityTestClient.NewUserName(), "Test User", IdentityTestClient.InitialPassword,
            Role.Operator, null, null);

        var response = await _api.SendAsync(HttpMethod.Post, "/api/users", admin, request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Unknown_plant_is_rejected()
    {
        var admin = await _api.LoginAsAdminAsync();
        var request = new CreateUserRequest(
            IdentityTestClient.NewUserName(), "Test User", IdentityTestClient.InitialPassword,
            Role.Operator, Guid.CreateVersion7(), null);

        var response = await _api.SendAsync(HttpMethod.Post, "/api/users", admin, request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Line_must_belong_to_the_plant()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var otherPlant = await _api.CreatePlantAsync(admin);
        var foreignMachine = await _api.CreateMachineAsync(admin, otherPlant.Id);

        var request = new CreateUserRequest(
            IdentityTestClient.NewUserName(), "Test User", IdentityTestClient.InitialPassword,
            Role.Operator, plant.Id, foreignMachine.LineId);
        var response = await _api.SendAsync(HttpMethod.Post, "/api/users", admin, request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task User_names_are_unique_across_plants()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var otherPlant = await _api.CreatePlantAsync(admin);
        var existing = await _api.CreateUserAsync(admin, Role.Operator, plant.Id);
        var otherPlantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, otherPlant.Id);

        // The existing user is hidden from this plant admin, yet the name must still be refused.
        var request = new CreateUserRequest(
            existing.UserName.ToUpperInvariant(), "Copy", IdentityTestClient.InitialPassword,
            Role.Operator, otherPlant.Id, null);
        var response = await _api.SendAsync(HttpMethod.Post, "/api/users", otherPlantAdmin.Tokens, request);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Plant_admin_cannot_see_or_change_users_of_another_plant()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var otherPlant = await _api.CreatePlantAsync(admin);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, plant.Id);
        var stranger = await _api.CreateUserAsync(admin, Role.Operator, otherPlant.Id);

        var get = await _api.SendAsync(HttpMethod.Get, $"/api/users/{stranger.Id}", plantAdmin.Tokens);
        var deactivate = await _api.SendAsync(
            HttpMethod.Post, $"/api/users/{stranger.Id}/deactivate", plantAdmin.Tokens);
        var list = await _api.SendAsync(HttpMethod.Get, "/api/users", plantAdmin.Tokens);

        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, deactivate.StatusCode);

        var visible = (await IdentityTestClient.ReadAsync<CursorPage<UserResponse>>(list)).Items;
        Assert.DoesNotContain(visible, user => user.Id == stranger.Id);
        Assert.All(visible, user => Assert.Equal(plant.Id, user.FactoryId));
    }

    [Fact]
    public async Task Plant_admin_cannot_create_users_in_another_plant()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var otherPlant = await _api.CreatePlantAsync(admin);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, plant.Id);

        var request = new CreateUserRequest(
            IdentityTestClient.NewUserName(), "Test User", IdentityTestClient.InitialPassword,
            Role.Operator, otherPlant.Id, null);
        var response = await _api.SendAsync(HttpMethod.Post, "/api/users", plantAdmin.Tokens, request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Changing_access_signs_the_user_out()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var user = await _api.CreateUserAsync(admin, Role.Operator, plant.Id);
        var userTokens = await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);

        var update = await _api.SendAsync(
            HttpMethod.Put, $"/api/users/{user.Id}/access", admin,
            new UpdateUserAccessRequest(Role.Supervisor, plant.Id, null));

        Assert.Equal(HttpStatusCode.OK, update.StatusCode);
        var updated = await IdentityTestClient.ReadAsync<UserResponse>(update);
        Assert.Equal(Role.Supervisor, updated.Role);

        var refresh = await _api.RefreshAsync(userTokens.RefreshToken);
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task Deactivated_user_cannot_sign_in_until_activated()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var user = await _api.CreateUserAsync(admin, Role.Technician, plant.Id);

        var deactivate = await _api.SendAsync(HttpMethod.Post, $"/api/users/{user.Id}/deactivate", admin);
        Assert.Equal(HttpStatusCode.NoContent, deactivate.StatusCode);
        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await _api.TryLoginAsync(user.UserName, IdentityTestClient.InitialPassword)).StatusCode);

        var activate = await _api.SendAsync(HttpMethod.Post, $"/api/users/{user.Id}/activate", admin);
        Assert.Equal(HttpStatusCode.NoContent, activate.StatusCode);
        await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);
    }

    [Fact]
    public async Task Password_reset_replaces_the_password_and_signs_the_user_out()
    {
        const string temporaryPassword = "Temporary-Password-2026";
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var user = await _api.CreateSignedInUserAsync(admin, Role.Manager, plant.Id);

        var reset = await _api.SendAsync(
            HttpMethod.Post, $"/api/users/{user.User.Id}/reset-password", admin,
            new ResetPasswordRequest(temporaryPassword));

        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);
        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await _api.TryLoginAsync(user.User.UserName, IdentityTestClient.ChosenPassword)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await _api.RefreshAsync(user.Tokens.RefreshToken)).StatusCode);

        // The admin knows the new password, so the user must replace it again.
        var tokens = await _api.LoginAsync(user.User.UserName, temporaryPassword);
        Assert.True(tokens.MustChangePassword);
    }

    [Fact]
    public async Task Admin_cannot_deactivate_themselves()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var plantAdmin = await _api.CreateSignedInUserAsync(admin, Role.Admin, plant.Id);

        var response = await _api.SendAsync(
            HttpMethod.Post, $"/api/users/{plantAdmin.User.Id}/deactivate", plantAdmin.Tokens);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}