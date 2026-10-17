using LeanAssistant.Application.Abstractions;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Infrastructure.Identity;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace LeanAssistant.UnitTests.Identity;

public class AuthServiceTests
{
    private const string Password = "Correct-Horse-42";

    private static readonly DateTimeOffset Now =
        new(2026, 10, 17, 8, 0, 0, TimeSpan.Zero);

    private readonly InMemoryUsers _users = new();
    private readonly InMemoryRefreshTokens _refreshTokens = new();
    private readonly CountingUnitOfWork _unitOfWork = new();
    private readonly AdjustableTimeProvider _clock = new(Now);
    private readonly User _user;
    private readonly AuthService _service;

    public AuthServiceTests()
    {
        _user = User.Create(
            "ali.sezer", "Ali Caner Sezer", FakePasswordHasher.HashOf(Password), Role.Operator);
        _users.Items.Add(_user);

        _service = new AuthService(
            _users,
            _refreshTokens,
            _unitOfWork,
            new FakePasswordHasher(),
            new RefreshTokenGenerator(),
            new FakeAccessTokenIssuer(),
            Options.Create(new AuthOptions()),
            _clock,
            NullLogger<AuthService>.Instance);
    }

    [Fact]
    public async Task Login_returns_tokens_and_stores_only_the_refresh_token_hash()
    {
        var tokens = await _service.LoginAsync("ali.sezer", Password, CancellationToken.None);

        Assert.NotNull(tokens);
        Assert.Equal($"access-{_user.Id}", tokens.AccessToken);
        Assert.Equal(Now.AddDays(7), tokens.RefreshTokenExpiresAt);

        var stored = Assert.Single(_refreshTokens.Items);
        Assert.Equal(_user.Id, stored.UserId);
        Assert.NotEqual(tokens.RefreshToken, stored.TokenHash);
        Assert.Equal(1, _unitOfWork.SaveCount);
    }

    [Fact]
    public async Task Login_ignores_user_name_case_and_spaces()
    {
        var tokens = await _service.LoginAsync("  ALI.Sezer ", Password, CancellationToken.None);

        Assert.NotNull(tokens);
    }

    [Fact]
    public async Task Login_with_wrong_password_fails_and_stores_nothing()
    {
        var tokens = await _service.LoginAsync("ali.sezer", "wrong-password", CancellationToken.None);

        Assert.Null(tokens);
        Assert.Empty(_refreshTokens.Items);
    }

    [Fact]
    public async Task Login_with_unknown_user_fails()
    {
        var tokens = await _service.LoginAsync("nobody", Password, CancellationToken.None);

        Assert.Null(tokens);
    }

    [Fact]
    public async Task Login_upgrades_an_old_password_hash()
    {
        var veteran = User.Create(
            "veteran", "Old Account", FakePasswordHasher.OldHashOf(Password), Role.Operator);
        _users.Items.Add(veteran);

        var tokens = await _service.LoginAsync("veteran", Password, CancellationToken.None);

        Assert.NotNull(tokens);
        Assert.Equal(FakePasswordHasher.HashOf(Password), veteran.PasswordHash);
    }

    [Fact]
    public async Task Refresh_rotates_the_token_within_the_same_family()
    {
        var first = await LoginAsync();

        var second = await _service.RefreshAsync(first.RefreshToken, CancellationToken.None);

        Assert.NotNull(second);
        Assert.NotEqual(first.RefreshToken, second.RefreshToken);

        Assert.Equal(2, _refreshTokens.Items.Count);
        var (old, next) = (_refreshTokens.Items[0], _refreshTokens.Items[1]);
        Assert.Equal(RefreshTokenRevocationReason.Rotated, old.RevocationReason);
        Assert.Equal(old.FamilyId, next.FamilyId);
        Assert.True(next.IsActive(Now));
    }

    [Fact]
    public async Task Reusing_a_rotated_token_revokes_the_whole_family()
    {
        var first = await LoginAsync();
        var second = await _service.RefreshAsync(first.RefreshToken, CancellationToken.None);
        Assert.NotNull(second);

        // An attacker (or a buggy client) sends the old token again.
        var reuse = await _service.RefreshAsync(first.RefreshToken, CancellationToken.None);

        Assert.Null(reuse);
        Assert.All(_refreshTokens.Items, token => Assert.True(token.IsRevoked));
        Assert.Equal(RefreshTokenRevocationReason.ReuseDetected, _refreshTokens.Items[1].RevocationReason);

        // The newest token is now useless too.
        Assert.Null(await _service.RefreshAsync(second.RefreshToken, CancellationToken.None));
    }

    [Fact]
    public async Task Expired_token_cannot_be_refreshed()
    {
        var tokens = await LoginAsync();
        _clock.Now = Now.AddDays(7);

        var result = await _service.RefreshAsync(tokens.RefreshToken, CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task Unknown_token_cannot_be_refreshed()
    {
        var result = await _service.RefreshAsync("not-a-real-token", CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task Logout_revokes_the_token()
    {
        var tokens = await LoginAsync();

        await _service.LogoutAsync(tokens.RefreshToken, CancellationToken.None);

        var stored = Assert.Single(_refreshTokens.Items);
        Assert.Equal(RefreshTokenRevocationReason.LoggedOut, stored.RevocationReason);
        Assert.Null(await _service.RefreshAsync(tokens.RefreshToken, CancellationToken.None));
    }

    private async Task<AuthTokens> LoginAsync()
    {
        var tokens = await _service.LoginAsync("ali.sezer", Password, CancellationToken.None);
        Assert.NotNull(tokens);
        return tokens;
    }

    /// <summary>Fast, predictable stand-in; the real hasher has its own tests.</summary>
    private sealed class FakePasswordHasher : IPasswordHasher
    {
        public static string HashOf(string password) => "hashed:" + password;

        public static string OldHashOf(string password) => "old-hashed:" + password;

        public string Hash(string password) => HashOf(password);

        public PasswordCheckResult Verify(string passwordHash, string password)
        {
            if (passwordHash == HashOf(password))
            {
                return PasswordCheckResult.Success;
            }

            return passwordHash == OldHashOf(password)
                ? PasswordCheckResult.SuccessRehashNeeded
                : PasswordCheckResult.Failed;
        }
    }

    private sealed class FakeAccessTokenIssuer : IAccessTokenIssuer
    {
        public AccessToken Issue(User user) => new($"access-{user.Id}", Now.AddMinutes(15));
    }

    private sealed class InMemoryUsers : IUserRepository
    {
        public List<User> Items { get; } = [];

        public Task<User?> FindByUserNameAsync(string userName, CancellationToken cancellationToken) =>
            Task.FromResult(Items.SingleOrDefault(user => user.UserName == userName));

        public Task<User?> FindByIdAsync(Guid id, CancellationToken cancellationToken) =>
            Task.FromResult(Items.SingleOrDefault(user => user.Id == id));

            
        public Task<bool> AnyAsync(CancellationToken cancellationToken) =>
            Task.FromResult(Items.Count > 0);

        public void Add(User user) => Items.Add(user);
    }

    private sealed class InMemoryRefreshTokens : IRefreshTokenRepository
    {
        public List<RefreshToken> Items { get; } = [];

        public Task<RefreshToken?> FindByHashAsync(string tokenHash, CancellationToken cancellationToken) =>
            Task.FromResult(Items.SingleOrDefault(token => token.TokenHash == tokenHash));

        public Task<IReadOnlyList<RefreshToken>> ListActiveInFamilyAsync(
            Guid familyId, CancellationToken cancellationToken) =>
            Task.FromResult<IReadOnlyList<RefreshToken>>(
                Items.Where(token => token.FamilyId == familyId && !token.IsRevoked).ToList());

        public void Add(RefreshToken token) => Items.Add(token);
    }

    private sealed class CountingUnitOfWork : IUnitOfWork
    {
        public int SaveCount { get; private set; }

        public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            SaveCount++;
            return Task.FromResult(0);
        }
    }

    private sealed class AdjustableTimeProvider(DateTimeOffset start) : TimeProvider
    {
        public DateTimeOffset Now { get; set; } = start;

        public override DateTimeOffset GetUtcNow() => Now;
    }
}