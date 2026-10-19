using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using LeanAssistant.Api.Identity;
using LeanAssistant.Application.Identity;

namespace LeanAssistant.IntegrationTests.Identity;

[Collection(ApiCollection.Name)]
public sealed class AuthEndpointsTests(ApiFactory factory)
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Health_check_is_public()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Me_requires_a_token()
    {
        var response = await _client.GetAsync("/api/auth/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Signed_in_user_can_read_their_own_profile()
    {
        var tokens = await LoginAsAdminAsync();

        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/auth/me");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", tokens.AccessToken);
        var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var me = await response.Content.ReadFromJsonAsync<CurrentUserResponse>();
        Assert.NotNull(me);
        Assert.Equal(ApiFactory.AdminUserName, me.UserName);
        Assert.Equal("Admin", me.Role);
    }

    [Fact]
    public async Task Wrong_password_is_rejected()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/auth/login", new LoginRequest(ApiFactory.AdminUserName, "wrong-password"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Empty_login_request_is_a_validation_error()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new LoginRequest("", ""));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Reusing_a_refresh_token_closes_the_whole_session()
    {
        var first = await LoginAsAdminAsync();

        var refreshed = await _client.PostAsJsonAsync(
            "/api/auth/refresh", new RefreshTokenRequest(first.RefreshToken));
        Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode);
        var second = await refreshed.Content.ReadFromJsonAsync<AuthTokens>();
        Assert.NotNull(second);

        // The old token is presented again, as an attacker with a copy would do.
        var reuse = await _client.PostAsJsonAsync(
            "/api/auth/refresh", new RefreshTokenRequest(first.RefreshToken));
        Assert.Equal(HttpStatusCode.Unauthorized, reuse.StatusCode);

        // The newest token of the same session no longer works either.
        var afterReuse = await _client.PostAsJsonAsync(
            "/api/auth/refresh", new RefreshTokenRequest(second.RefreshToken));
        Assert.Equal(HttpStatusCode.Unauthorized, afterReuse.StatusCode);
    }

    private async Task<AuthTokens> LoginAsAdminAsync()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/auth/login", new LoginRequest(ApiFactory.AdminUserName, ApiFactory.AdminPassword));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var tokens = await response.Content.ReadFromJsonAsync<AuthTokens>();
        Assert.NotNull(tokens);
        return tokens;
    }
}