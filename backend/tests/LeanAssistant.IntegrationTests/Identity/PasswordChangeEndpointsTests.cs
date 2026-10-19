using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using LeanAssistant.Api.Identity;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.IntegrationTests.Identity;

[Collection(ApiCollection.Name)]
public sealed class PasswordChangeEndpointsTests(ApiFactory factory)
{
    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Fact]
    public async Task Temporary_password_only_opens_the_identity_endpoints()
    {
        var admin = await _api.LoginAsAdminAsync();
        // An admin role passes the ManageUsers check, so a 403 can only come from the lock.
        var plantAdmin = await _api.CreateUserAsync(admin, Role.Admin, Guid.CreateVersion7());
        var tokens = await _api.LoginAsync(plantAdmin.UserName, IdentityTestClient.InitialPassword);

        var me = await _api.SendAsync(HttpMethod.Get, "/api/auth/me", tokens);
        var users = await _api.SendAsync(HttpMethod.Get, "/api/users", tokens);

        Assert.Equal(HttpStatusCode.OK, me.StatusCode);
        var profile = await IdentityTestClient.ReadAsync<CurrentUserResponse>(me);
        Assert.True(profile.MustChangePassword);

        Assert.Equal(HttpStatusCode.Forbidden, users.StatusCode);
        var problem = await users.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(PasswordChangeRequiredMiddleware.ErrorCode, problem.GetProperty("code").GetString());
    }

    [Fact]
    public async Task Changing_the_password_unlocks_the_api_and_closes_other_sessions()
    {
        var admin = await _api.LoginAsAdminAsync();
        var user = await _api.CreateUserAsync(admin, Role.Admin, Guid.CreateVersion7());
        var phone = await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);
        var tablet = await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);

        var changed = await _api.ChangePasswordAsync(
            phone, IdentityTestClient.InitialPassword, IdentityTestClient.ChosenPassword);

        Assert.False(changed.MustChangePassword);
        Assert.Equal(
            HttpStatusCode.OK,
            (await _api.SendAsync(HttpMethod.Get, "/api/users", changed)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await _api.RefreshAsync(tablet.RefreshToken)).StatusCode);
        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await _api.TryLoginAsync(user.UserName, IdentityTestClient.InitialPassword)).StatusCode);
        await _api.LoginAsync(user.UserName, IdentityTestClient.ChosenPassword);
    }

    [Fact]
    public async Task Wrong_current_password_is_rejected()
    {
        var admin = await _api.LoginAsAdminAsync();
        var user = await _api.CreateUserAsync(admin, Role.Operator, Guid.CreateVersion7());
        var tokens = await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);

        var response = await _api.TryChangePasswordAsync(
            tokens, "Not-The-Current-Password", IdentityTestClient.ChosenPassword);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task New_password_must_differ_from_the_current_one()
    {
        var admin = await _api.LoginAsAdminAsync();
        var user = await _api.CreateUserAsync(admin, Role.Operator, Guid.CreateVersion7());
        var tokens = await _api.LoginAsync(user.UserName, IdentityTestClient.InitialPassword);

        var response = await _api.TryChangePasswordAsync(
            tokens, IdentityTestClient.InitialPassword, IdentityTestClient.InitialPassword);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}