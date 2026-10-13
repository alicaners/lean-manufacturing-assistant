using LeanAssistant.Domain.SharedKernel;

namespace LeanAssistant.UnitTests.SharedKernel;

public class EntityTests
{
    private static readonly DateTimeOffset Now =
        new(2026, 10, 13, 6, 0, 0, TimeSpan.Zero);

    [Fact]
    public void New_entities_get_unique_non_empty_ids()
    {
        var first = new TestEntity();
        var second = new TestEntity();

        Assert.NotEqual(Guid.Empty, first.Id);
        Assert.NotEqual(first.Id, second.Id);
    }

    [Fact]
    public void MarkCreated_sets_created_and_updated_time()
    {
        var entity = new TestEntity();

        entity.MarkCreated(Now);

        Assert.Equal(Now, entity.CreatedAt);
        Assert.Equal(Now, entity.UpdatedAt);
    }

    [Fact]
    public void MarkDeleted_twice_keeps_first_deletion_time()
    {
        var entity = new TestEntity();
        var later = Now.AddHours(1);

        entity.MarkDeleted(Now);
        entity.MarkDeleted(later);

        Assert.True(entity.IsDeleted);
        Assert.Equal(Now, entity.DeletedAt);
    }

    [Fact]
    public void Non_utc_time_is_rejected()
    {
        var entity = new TestEntity();
        var istanbulTime = new DateTimeOffset(2026, 10, 13, 9, 0, 0, TimeSpan.FromHours(3));

        Assert.Throws<ArgumentException>(() => entity.MarkCreated(istanbulTime));
    }

    private sealed class TestEntity : Entity
    {
    }
}