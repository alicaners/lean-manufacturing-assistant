using System.Net;
using LeanAssistant.Application.Identity;

namespace LeanAssistant.IntegrationTests.Identity;

/// <summary>
/// The mobile app sends one refresh at a time and lets other requests wait for it.
/// These tests show why: a refresh token can be exchanged only once, so parallel
/// refreshes with the same token never split one sign-in into two working sessions.
/// </summary>
[Collection(ApiCollection.Name)]
public sealed class TokenRefreshConcurrencyTests(ApiFactory factory)
{
    private const int ParallelRequests = 10;

    private readonly IdentityTestClient _identity = new(factory.CreateClient());

    [Fact]
    public async Task Parallel_refreshes_with_the_same_token_let_only_one_through()
    {
        var session = await _identity.LoginAsAdminAsync();

        var responses = await Task.WhenAll(
            Enumerable.Range(0, ParallelRequests)
                .Select(_ => _identity.RefreshAsync(session.RefreshToken)));

        // Exactly one request exchanges the token.
        Assert.Single(responses, response => response.StatusCode == HttpStatusCode.OK);

        // The others either lost the race on the same row (409)
        // or came after it and were treated as token reuse (401).
        Assert.All(
            responses.Where(response => response.StatusCode != HttpStatusCode.OK),
            response => Assert.Contains(
                response.StatusCode, new[] { HttpStatusCode.Conflict, HttpStatusCode.Unauthorized }));
    }

    [Fact]
    public async Task Refreshing_one_at_a_time_keeps_the_session_alive()
    {
        var session = await _identity.LoginAsAdminAsync();

        // What the app does: every refresh uses the newest token.
        for (var refresh = 0; refresh < 3; refresh++)
        {
            var response = await _identity.RefreshAsync(session.RefreshToken);

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            session = await IdentityTestClient.ReadAsync<AuthTokens>(response);
        }
    }
}