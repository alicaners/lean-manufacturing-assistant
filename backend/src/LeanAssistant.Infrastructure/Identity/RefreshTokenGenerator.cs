using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;
using LeanAssistant.Application.Identity;

namespace LeanAssistant.Infrastructure.Identity;

/// <summary>
/// Refresh tokens are 256 random bits. Because they cannot be guessed, a fast hash
/// (SHA-256) is enough to protect them at rest; a slow hash like PBKDF2 is only
/// needed for passwords, which people choose and attackers can guess.
/// </summary>
public sealed class RefreshTokenGenerator : IRefreshTokenGenerator
{
    private const int TokenSizeInBytes = 32;

    public GeneratedRefreshToken Generate()
    {
        var bytes = RandomNumberGenerator.GetBytes(TokenSizeInBytes);
        var token = Base64Url.EncodeToString(bytes);

        return new GeneratedRefreshToken(token, Hash(token));
    }

    public string Hash(string token)
    {
        ArgumentException.ThrowIfNullOrEmpty(token);

        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));

        // 32 bytes as upper-case hexadecimal: always 64 characters,
        // matching the character(64) column.
        return Convert.ToHexString(hash);
    }
}