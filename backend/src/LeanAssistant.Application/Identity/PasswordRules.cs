namespace LeanAssistant.Application.Identity;

/// <summary>Length limits for every password a person chooses or an admin sets.</summary>
public static class PasswordRules
{
    public const int MinimumLength = 12;

    /// <summary>Huge inputs would keep the server busy with slow hashing.</summary>
    public const int MaximumLength = 128;
}