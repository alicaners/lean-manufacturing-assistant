using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.Domain.Identity;

/// <summary>
/// A person who can sign in to the app.
/// The password itself is never stored, only its hash.
/// </summary>
public sealed class User : Entity
{
    public const int UserNameMaxLength = 64;
    public const int FullNameMaxLength = 128;

    // Used by EF Core when it reads a user from the database.
    private User()
    {
    }

    private User(string userName, string fullName, string passwordHash, Role role)
    {
        UserName = userName;
        FullName = fullName;
        PasswordHash = passwordHash;
        Role = role;
        IsActive = true;
    }

    /// <summary>Sign-in name, e.g. the employee number. Always lower case.</summary>
    public string UserName { get; private set; } = null!;

    public string FullName { get; private set; } = null!;

    public string PasswordHash { get; private set; } = null!;

    public Role Role { get; private set; }

    /// <summary>Inactive users cannot sign in or refresh their session.</summary>
    public bool IsActive { get; private set; }

    public static User Create(string userName, string fullName, string passwordHash, Role role)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(userName);
        ArgumentException.ThrowIfNullOrWhiteSpace(fullName);
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);

        if (!Enum.IsDefined(role))
        {
            throw new ArgumentOutOfRangeException(nameof(role), role, "Unknown role.");
        }

        var normalizedUserName = NormalizeUserName(userName);
        var trimmedFullName = fullName.Trim();

        if (normalizedUserName.Length > UserNameMaxLength)
        {
            throw new ArgumentException(
                $"User name cannot be longer than {UserNameMaxLength} characters.", nameof(userName));
        }

        if (trimmedFullName.Length > FullNameMaxLength)
        {
            throw new ArgumentException(
                $"Full name cannot be longer than {FullNameMaxLength} characters.", nameof(fullName));
        }

        return new User(normalizedUserName, trimmedFullName, passwordHash, role);
    }

    /// <summary>
    /// " Ali.Sezer " and "ali.sezer" must be the same user,
    /// so user names are always compared in this form.
    /// </summary>
    public static string NormalizeUserName(string userName) =>
        userName.Trim().ToLowerInvariant();

    /// <summary>
    /// Replaces the stored hash, e.g. after a password change or when the
    /// hashing algorithm's settings have become stronger.
    /// </summary>
    public void ReplacePasswordHash(string passwordHash)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);
        PasswordHash = passwordHash;
    }
}