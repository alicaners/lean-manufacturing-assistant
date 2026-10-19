namespace LeanAssistant.Application.Identity;

/// <summary>Creates random refresh tokens and the hashes we store for them.</summary>
public interface IRefreshTokenGenerator
{
    GeneratedRefreshToken Generate();

    /// <summary>Hash of a token the client sent back, used to look it up.</summary>
    string Hash(string token);
}

/// <param name="Token">Sent to the client once; never stored.</param>
/// <param name="TokenHash">Stored in the database.</param>
public sealed record GeneratedRefreshToken(string Token, string TokenHash);