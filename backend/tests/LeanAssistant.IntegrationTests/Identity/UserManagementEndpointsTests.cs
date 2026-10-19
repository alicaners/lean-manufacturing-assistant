using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using LeanAssistant.Api.Identity;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.IntegrationTests.Identity;

[Collection(ApiCollection.Name)]
public sealed class UserManagementEndpointsTests(ApiFactory factory)
{
    private const string UserPassword = "Integration-Test-User-Password";

    // The API writes enums as text ("Operator"), so the test client reads and writes them the same way.
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() }
    };

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Users_endpoint_requires_a_token()
    {
        var response = await _client.GetAsync("/api/users");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Operator_cannot_manage_users()
    {
        var admin = await LoginAsAdminAsync();
        var operatorUser = await CreateUserAsync(admin, Role.Operator, Guid.CreateVersion7());
        var operatorTokens = await LoginAsync(operatorUser.UserName, UserPassword);

        var response = await SendAsync(HttpMethod.Get, "/api/users", operatorTokens);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_creates_a_user_who_can_sign_in()
    {
        var admin = await LoginAsAdminAsync();
        var plantId = Guid.CreateVersion7();

        var user = await CreateUserAsync(admin, Role.Operator, plantId);

        Assert.Equal(Role.Operator, user.Role);
        Assert.Equal(plantId, user.FactoryId);
        Assert.True(user.IsActive);
        await LoginAsync(user.UserName, UserPassword);
    }

    [Fact]
    public async Task Every_role_except_admin_needs_a_plant()
    {
        var admin = await LoginAsAdminAsync();
        var request = new CreateUserRequest(NewUserName(), "Test User", UserPassword, Role.Operator, null, null);

        var response = await SendAsync(HttpMethod.Post, "/api/users", admin, request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task User_names_are_unique_across_plants()
    {
        var admin = await LoginAsAdminAsync();
        var existing = await CreateUserAsync(admin, Role.Operator, Guid.CreateVersion7());
        var otherPlantAdmin = await CreatePlantAdminAsync(admin, Guid.CreateVersion7());

        // The existing user is hidden from this plant admin, yet the name must still be refused.
        var request = new CreateUserRequest(
            existing.UserName.ToUpperInvariant(), "Copy", UserPassword, Role.Operator,
            otherPlantAdmin.PlantId, null);
        var response = await SendAsync(HttpMethod.Post, "/api/users", otherPlantAdmin.Tokens, request);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Plant_admin_cannot_see_or_change_users_of_another_plant()
    {
        var admin = await LoginAsAdminAsync();
        var plantAdmin = await CreatePlantAdminAsync(admin, Guid.CreateVersion7());
        var stranger = await CreateUserAsync(admin, Role.Operator, Guid.CreateVersion7());

        var get = await SendAsync(HttpMethod.Get, $"/api/users/{stranger.Id}", plantAdmin.Tokens);
        var deactivate = await SendAsync(
            HttpMethod.Post, $"/api/users/{stranger.Id}/deactivate", plantAdmin.Tokens);
        var list = await SendAsync(HttpMethod.Get, "/api/users", plantAdmin.Tokens);

        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, deactivate.StatusCode);

        var visible = await list.Content.ReadFromJsonAsync<List<UserResponse>>(Json);
        Assert.NotNull(visible);
        Assert.DoesNotContain(visible, user => user.Id == stranger.Id);
        Assert.All(visible, user => Assert.Equal(plantAdmin.PlantId, user.FactoryId));
    }

    [Fact]
    public async Task Plant_admin_cannot_create_users_in_another_plant()
    {
        var admin = await LoginAsAdminAsync();
        var plantAdmin = await CreatePlantAdminAsync(admin, Guid.CreateVersion7());
        var request = new CreateUserRequest(
            NewUserName(), "Test User", UserPassword, Role.Operator, Guid.CreateVersion7(), null);

        var response = await SendAsync(HttpMethod.Post, "/api/users", plantAdmin.Tokens, request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Changing_access_signs_the_user_out()
    {
        var admin = await LoginAsAdminAsync();
        var plantId = Guid.CreateVersion7();
        var user = await CreateUserAsync(admin, Role.Operator, plantId);
        var userTokens = await LoginAsync(user.UserName, UserPassword);

        var update = await SendAsync(
            HttpMethod.Put, $"/api/users/{user.Id}/access", admin,
            new UpdateUserAccessRequest(Role.Supervisor, plantId, null));

        Assert.Equal(HttpStatusCode.OK, update.StatusCode);
        var updated = await update.Content.ReadFromJsonAsync<UserResponse>(Json);
        Assert.Equal(Role.Supervisor, updated?.Role);

        var refresh = await RefreshAsync(userTokens.RefreshToken);
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task Deactivated_user_cannot_sign_in_until_activated()
    {
        var admin = await LoginAsAdminAsync();
        var user = await CreateUserAsync(admin, Role.Technician, Guid.CreateVersion7());

        var deactivate = await SendAsync(HttpMethod.Post, $"/api/users/{user.Id}/deactivate", admin);
        Assert.Equal(HttpStatusCode.NoContent, deactivate.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await TryLoginAsync(user.UserName, UserPassword)).StatusCode);

        var activate = await SendAsync(HttpMethod.Post, $"/api/users/{user.Id}/activate", admin);
        Assert.Equal(HttpStatusCode.NoContent, activate.StatusCode);
        await LoginAsync(user.UserName, UserPassword);
    }

    [Fact]
    public async Task Password_reset_replaces_the_password_and_signs_the_user_out()
    {
        const string temporaryPassword = "Temporary-Password-2026";
        var admin = await LoginAsAdminAsync();
        var user = await CreateUserAsync(admin, Role.Manager, Guid.CreateVersion7());
        var oldTokens = await LoginAsync(user.UserName, UserPassword);

        var reset = await SendAsync(
            HttpMethod.Post, $"/api/users/{user.Id}/reset-password", admin,
            new ResetPasswordRequest(temporaryPassword));

        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await TryLoginAsync(user.UserName, UserPassword)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await RefreshAsync(oldTokens.RefreshToken)).StatusCode);
        await LoginAsync(user.UserName, temporaryPassword);
    }

    [Fact]
    public async Task Admin_cannot_deactivate_themselves()
    {
        var admin = await LoginAsAdminAsync();
        var plantAdmin = await CreatePlantAdminAsync(admin, Guid.CreateVersion7());

        var response = await SendAsync(
            HttpMethod.Post, $"/api/users/{plantAdmin.UserId}/deactivate", plantAdmin.Tokens);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private sealed record PlantAdmin(Guid UserId, Guid PlantId, AuthTokens Tokens);

    /// <summary>An admin bound to one plant, already signed in.</summary>
    private async Task<PlantAdmin> CreatePlantAdminAsync(AuthTokens systemAdmin, Guid plantId)
    {
        var user = await CreateUserAsync(systemAdmin, Role.Admin, plantId);
        var tokens = await LoginAsync(user.UserName, UserPassword);
        return new PlantAdmin(user.Id, plantId, tokens);
    }

    private async Task<UserResponse> CreateUserAsync(AuthTokens caller, Role role, Guid? plantId)
    {
        var request = new CreateUserRequest(NewUserName(), "Test User", UserPassword, role, plantId, null);
        var response = await SendAsync(HttpMethod.Post, "/api/users", caller, request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(response.Headers.Location);

        var user = await response.Content.ReadFromJsonAsync<UserResponse>(Json);
        Assert.NotNull(user);
        return user;
    }

    private Task<AuthTokens> LoginAsAdminAsync() =>
        LoginAsync(ApiFactory.AdminUserName, ApiFactory.AdminPassword);

    private async Task<AuthTokens> LoginAsync(string userName, string password)
    {
        var response = await TryLoginAsync(userName, password);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var tokens = await response.Content.ReadFromJsonAsync<AuthTokens>(Json);
        Assert.NotNull(tokens);
        return tokens;
    }

    private Task<HttpResponseMessage> TryLoginAsync(string userName, string password) =>
        _client.PostAsJsonAsync("/api/auth/login", new LoginRequest(userName, password));

    private Task<HttpResponseMessage> RefreshAsync(string refreshToken) =>
        _client.PostAsJsonAsync("/api/auth/refresh", new RefreshTokenRequest(refreshToken));

    private async Task<HttpResponseMessage> SendAsync(
        HttpMethod method, string url, AuthTokens caller, object? body = null)
    {
        using var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", caller.AccessToken);

        if (body is not null)
        {
            request.Content = JsonContent.Create(body, body.GetType(), options: Json);
        }

        return await _client.SendAsync(request);
    }

    // Every test makes its own users, so tests sharing one database never collide.
    private static string NewUserName() => $"user-{Guid.NewGuid():N}";
}