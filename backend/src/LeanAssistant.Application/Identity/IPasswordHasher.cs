namespace LeanAssistant.Application.Identity;

/// <summary>Turns passwords into hashes and checks a password against a stored hash.</summary>
public interface IPasswordHasher
{
    string Hash(string password);

    PasswordCheckResult Verify(string passwordHash, string password);
}

public enum PasswordCheckResult
{
    Failed,
    Success,

    /// <summary>
    /// The password is correct, but the hash uses older, weaker settings
    /// and should be replaced with a new one.
    /// </summary>
    SuccessRehashNeeded
}