namespace LeanAssistant.Domain.SharedKernel;

/// <summary>Small input checks shared by entities. Holds no business rules.</summary>
public static class Guard
{
    /// <summary>Trims the text and checks that it is neither empty nor too long.</summary>
    public static string Text(string value, int maxLength, string paramName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(value, paramName);

        var trimmed = value.Trim();
        if (trimmed.Length > maxLength)
        {
            throw new ArgumentException($"Cannot be longer than {maxLength} characters.", paramName);
        }

        return trimmed;
    }
}