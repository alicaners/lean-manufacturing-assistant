using LeanAssistant.Infrastructure.Identity;

namespace LeanAssistant.UnitTests.Identity;

public class RefreshTokenGeneratorTests
{
    private readonly RefreshTokenGenerator _generator = new();

    [Fact]
    public void Generated_tokens_are_unique()
    {
        var first = _generator.Generate();
        var second = _generator.Generate();

        Assert.NotEqual(first.Token, second.Token);
        Assert.NotEqual(first.TokenHash, second.TokenHash);
    }

    [Fact]
    public void Stored_hash_is_64_hex_characters_and_matches_the_token()
    {
        var generated = _generator.Generate();

        Assert.Matches("^[0-9A-F]{64}$", generated.TokenHash);
        Assert.Equal(generated.TokenHash, _generator.Hash(generated.Token));
        Assert.NotEqual(generated.Token, generated.TokenHash);
    }
}