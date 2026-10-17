using LeanAssistant.Application.Identity;
using LeanAssistant.Infrastructure.Identity;

namespace LeanAssistant.UnitTests.Identity;

public class IdentityPasswordHasherTests
{
    private const string Password = "Correct-Horse-42";

    private readonly IdentityPasswordHasher _hasher = new();

    [Fact]
    public void Hash_does_not_contain_the_password()
    {
        var hash = _hasher.Hash(Password);

        Assert.DoesNotContain(Password, hash);
    }

    [Fact]
    public void Same_password_gives_different_hashes_because_of_the_salt()
    {
        var first = _hasher.Hash(Password);
        var second = _hasher.Hash(Password);

        Assert.NotEqual(first, second);
    }

    [Fact]
    public void Correct_password_is_accepted()
    {
        var hash = _hasher.Hash(Password);

        Assert.Equal(PasswordCheckResult.Success, _hasher.Verify(hash, Password));
    }

    [Fact]
    public void Wrong_password_is_rejected()
    {
        var hash = _hasher.Hash(Password);

        Assert.Equal(PasswordCheckResult.Failed, _hasher.Verify(hash, "correct-horse-42"));
    }
}