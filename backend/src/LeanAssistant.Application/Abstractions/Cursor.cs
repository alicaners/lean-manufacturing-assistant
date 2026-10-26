using System.Buffers.Text;
using System.Diagnostics.CodeAnalysis;
using System.Text.Json;

namespace LeanAssistant.Application.Abstractions;

/// <summary>
/// Turns "the last row of the previous page" into an opaque string for the client and back.
/// The client never looks inside; it only sends the value back to get the next page.
/// </summary>
public static class Cursor
{
    public static string Encode<T>(T position) =>
        Base64Url.EncodeToString(JsonSerializer.SerializeToUtf8Bytes(position));

    /// <summary>False for a missing, damaged or foreign cursor.</summary>
    public static bool TryDecode<T>(string? cursor, [NotNullWhen(true)] out T? position)
        where T : class
    {
        position = null;

        if (string.IsNullOrEmpty(cursor))
        {
            return false;
        }

        try
        {
            position = JsonSerializer.Deserialize<T>(Base64Url.DecodeFromChars(cursor));
            return position is not null;
        }
        catch (Exception exception) when (exception is FormatException or JsonException)
        {
            return false;
        }
    }
}