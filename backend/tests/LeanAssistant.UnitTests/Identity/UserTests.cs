using LeanAssistant.Domain.Identity;

namespace LeanAssistant.UnitTests.Identity;

public class UserTests
{
    [Fact]
    public void Create_normalizes_user_name_and_trims_full_name()
    {
        var user = User.Create("  Ali.Sezer ", " Ali Caner Sezer ", "hash", Role.Operator);

        Assert.Equal("ali.sezer", user.UserName);
        Assert.Equal("Ali Caner Sezer", user.FullName);
    }

    [Fact]
    public void New_user_is_active()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        Assert.True(user.IsActive);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_rejects_empty_user_name(string userName)
    {
        Assert.Throws<ArgumentException>(
            () => User.Create(userName, "Ali Caner Sezer", "hash", Role.Operator));
    }

    [Fact]
    public void Create_rejects_too_long_user_name()
    {
        var tooLong = new string('a', User.UserNameMaxLength + 1);

        Assert.Throws<ArgumentException>(
            () => User.Create(tooLong, "Ali Caner Sezer", "hash", Role.Operator));
    }

    [Fact]
    public void Create_rejects_unknown_role()
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => User.Create("ali.sezer", "Ali Caner Sezer", "hash", (Role)99));
    }
}