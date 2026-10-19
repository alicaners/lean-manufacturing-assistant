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

    
    [Fact]
    public void AssignScope_sets_plant_and_line()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);
        var factoryId = Guid.CreateVersion7();
        var lineId = Guid.CreateVersion7();

        user.AssignScope(factoryId, lineId);

        Assert.Equal(factoryId, user.FactoryId);
        Assert.Equal(lineId, user.LineId);
    }

    [Fact]
    public void Line_without_a_plant_is_rejected()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        Assert.Throws<ArgumentException>(() => user.AssignScope(null, Guid.CreateVersion7()));
    }

    [Fact]
    public void New_user_has_no_scope()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        Assert.Null(user.FactoryId);
        Assert.Null(user.LineId);
    }

    
    [Fact]
    public void ChangeRole_sets_the_new_role()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        user.ChangeRole(Role.Supervisor);

        Assert.Equal(Role.Supervisor, user.Role);
    }

    [Fact]
    public void ChangeRole_rejects_an_unknown_role()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        Assert.Throws<ArgumentOutOfRangeException>(() => user.ChangeRole((Role)99));
    }

    [Fact]
    public void Deactivated_user_can_be_activated_again()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        user.Deactivate();
        Assert.False(user.IsActive);

        user.Activate();
        Assert.True(user.IsActive);
    }
    
    [Fact]
    public void New_user_does_not_have_to_change_password()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);

        Assert.False(user.MustChangePassword);
    }

    [Fact]
    public void Changing_the_password_clears_a_required_change()
    {
        var user = User.Create("ali.sezer", "Ali Caner Sezer", "hash", Role.Operator);
        user.RequirePasswordChange();
        Assert.True(user.MustChangePassword);

        user.ChangePassword("new-hash");

        Assert.False(user.MustChangePassword);
        Assert.Equal("new-hash", user.PasswordHash);
    }
}