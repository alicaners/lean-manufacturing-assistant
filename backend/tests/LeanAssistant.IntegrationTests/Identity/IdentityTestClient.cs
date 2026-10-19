using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.IntegrationTests.Identity;

/// <summary>A user who has signed in and already replaced their temporary password.</summary>
public sealed record SignedInUser(UserResponse User, AuthTokens Tokens);

/// <summary>
/// Calls the identity endpoints the way the mobile app does.
/// Shared by the identity test classes.
/// </summary>
internal sealed class IdentityTestClient(HttpClient http)
{
    /// <summary>The password an admin gives a new user; it must be changed at first sign-in.</summary>
    public const string InitialPassword = "Integration-Test-User-Password";

    /// <summary>The password the user picks to replace the initial one.</summary>
    public const string ChosenPassword = "Integration-Test-Chosen-Password";

    // The API writes enums as text ("Operator"), so the test client reads and writes them the same way.
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() }
    };

    public HttpClient Http => http;

    public Task<AuthTokens> LoginAsAdminAsync() =>
        LoginAsync(ApiFactory.AdminUserName, ApiFactory.AdminPassword);

    public async Task<AuthTokens> LoginAsync(string userName, string password)
    {
        var response = await TryLoginAsync(userName, password);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await ReadAsync<AuthTokens>(response);
    }

    public Task<HttpResponseMessage> TryLoginAsync(string userName, string password) =>
        http.PostAsJsonAsync("/api/auth/login", new LoginRequest(userName, password), Json);

    public Task<HttpResponseMessage> RefreshAsync(string refreshToken) =>
        http.PostAsJsonAsync("/api/auth/refresh", new RefreshTokenRequest(refreshToken), Json);

    public async Task<AuthTokens> ChangePasswordAsync(
        AuthTokens caller, string currentPassword, string newPassword)
    {
        var response = await TryChangePasswordAsync(caller, currentPassword, newPassword);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await ReadAsync<AuthTokens>(response);
    }

    public Task<HttpResponseMessage> TryChangePasswordAsync(
        AuthTokens caller, string currentPassword, string newPassword) =>
        SendAsync(
            HttpMethod.Post, "/api/auth/change-password", caller,
            new ChangePasswordRequest(currentPassword, newPassword));

    public async Task<HttpResponseMessage> SendAsync(
        HttpMethod method, string url, AuthTokens caller, object? body = null)
    {
        using var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", caller.AccessToken);

        if (body is not null)
        {
            request.Content = JsonContent.Create(body, body.GetType(), options: Json);
        }

        return await http.SendAsync(request);
    }

    public async Task<UserResponse> CreateUserAsync(AuthTokens caller, Role role, Guid? plantId)
    {
        var request = new CreateUserRequest(NewUserName(), "Test User", InitialPassword, role, plantId, null);
        var response = await SendAsync(HttpMethod.Post, "/api/users", caller, request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(response.Headers.Location);
        return await ReadAsync<UserResponse>(response);
    }

    /// <summary>
    /// Creates a user, signs in with the temporary password and replaces it,
    /// exactly like a real first sign-in. The returned tokens are not locked.
    /// </summary>
    public async Task<SignedInUser> CreateSignedInUserAsync(AuthTokens caller, Role role, Guid? plantId)
    {
        var user = await CreateUserAsync(caller, role, plantId);
        var temporary = await LoginAsync(user.UserName, InitialPassword);
        var tokens = await ChangePasswordAsync(temporary, InitialPassword, ChosenPassword);

        return new SignedInUser(user, tokens);
    }

    public static async Task<T> ReadAsync<T>(HttpResponseMessage response)
        where T : class
    {
        var value = await response.Content.ReadFromJsonAsync<T>(Json);
        Assert.NotNull(value);
        return value;
    }

    // Every test makes its own users, so tests sharing one database never collide.
    public static string NewUserName() => $"user-{Guid.NewGuid():N}";
}