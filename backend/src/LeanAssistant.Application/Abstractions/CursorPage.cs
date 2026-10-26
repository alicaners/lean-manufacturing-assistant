namespace LeanAssistant.Application.Abstractions;

/// <summary>
/// One page of a list. Send <paramref name="NextCursor"/> back to get the next page;
/// null means this was the last page.
/// </summary>
public sealed record CursorPage<T>(T[] Items, string? NextCursor);

/// <summary>Page sizes shared by every paged list.</summary>
public static class Paging
{
    public const int DefaultLimit = 20;

    /// <summary>Upper bound, so one request cannot ask for the whole table.</summary>
    public const int MaxLimit = 100;
}