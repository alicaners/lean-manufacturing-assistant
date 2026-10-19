using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using Microsoft.AspNetCore.Identity;

namespace LeanAssistant.Infrastructure.Identity;

/// <summary>
/// PBKDF2 with HMAC-SHA512, 100 000 iterations and a random salt per password,
/// using ASP.NET Core Identity's well-tested implementation.
/// </summary>
public sealed class IdentityPasswordHasher : IPasswordHasher
{
    private readonly PasswordHasher<User> _hasher = new();

    public string Hash(string password)
    {
        ArgumentException.ThrowIfNullOrEmpty(password);

        // The built-in hasher does not use the user object, so none is passed.
        return _hasher.HashPassword(null!, password);
    }

    public PasswordCheckResult Verify(string passwordHash, string password)
    {
        if (string.IsNullOrEmpty(passwordHash) || string.IsNullOrEmpty(password))
        {
            return PasswordCheckResult.Failed;
        }

        return _hasher.VerifyHashedPassword(null!, passwordHash, password) switch
        {
            PasswordVerificationResult.Success => PasswordCheckResult.Success,
            PasswordVerificationResult.SuccessRehashNeeded => PasswordCheckResult.SuccessRehashNeeded,
            _ => PasswordCheckResult.Failed
        };
    }
}