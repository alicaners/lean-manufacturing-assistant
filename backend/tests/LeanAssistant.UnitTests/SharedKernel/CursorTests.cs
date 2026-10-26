using LeanAssistant.Application.Abstractions;

namespace LeanAssistant.UnitTests.SharedKernel;

public class CursorTests
{
    private sealed record Position(string UserName);

    [Fact]
    public void Position_survives_the_round_trip()
    {
        var cursor = Cursor.Encode(new Position("ali.sezer"));

        Assert.True(Cursor.TryDecode<Position>(cursor, out var position));
        Assert.Equal("ali.sezer", position.UserName);
    }

    [Fact]
    public void Cursor_is_safe_in_a_url()
    {
        var cursor = Cursor.Encode(new Position("ğüşıöç & ? / +"));

        Assert.Matches("^[A-Za-z0-9_-]+$", cursor);
    }

    [Theory]
    [InlineData("not base64 !!")]
    [InlineData("aGVsbG8")] // valid Base64Url of "hello", but not a position
    public void Damaged_cursor_is_rejected(string cursor)
    {
        Assert.False(Cursor.TryDecode<Position>(cursor, out _));
    }
}