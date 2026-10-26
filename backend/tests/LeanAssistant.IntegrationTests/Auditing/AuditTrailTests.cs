using System.Net;
using System.Text.Json;
using LeanAssistant.Api.Identity;
using LeanAssistant.Application.Identity;
using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Auditing;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Domain.Organization;
using LeanAssistant.Infrastructure.Persistence;
using LeanAssistant.IntegrationTests.Identity;
using LeanAssistant.IntegrationTests.Organization;
using Microsoft.EntityFrameworkCore;

namespace LeanAssistant.IntegrationTests.Auditing;

[Collection(ApiCollection.Name)]
public sealed class AuditTrailTests(ApiFactory factory)
{
    private readonly IdentityTestClient _api = new(factory.CreateClient());

    [Fact]
    public async Task Creating_a_record_stores_who_did_it_and_the_values()
    {
        var admin = await _api.LoginAsAdminAsync();
        var adminId = await CurrentUserIdAsync(admin);
        var plant = await _api.CreatePlantAsync(admin);

        var machine = await _api.CreateMachineAsync(admin, plant.Id);

        var entry = Assert.Single(await EntriesForAsync(machine.Id));
        Assert.Equal(AuditAction.Created, entry.Action);
        Assert.Equal(nameof(Machine), entry.EntityType);
        Assert.Equal(adminId, entry.UserId);
        Assert.Equal(plant.Id, entry.FactoryId);
        Assert.Equal("Pres 4", Change(entry, "Name").GetProperty("new").GetString());
    }

    [Fact]
    public async Task Renaming_stores_the_old_and_the_new_value()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var machine = await _api.CreateMachineAsync(admin, plant.Id);

        var rename = await _api.SendAsync(
            HttpMethod.Put, $"/api/machines/{machine.Id}", admin, new NameRequest("Pres 4B"));
        Assert.Equal(HttpStatusCode.OK, rename.StatusCode);

        var update = Assert.Single(await EntriesForAsync(machine.Id), entry => entry.Action == AuditAction.Updated);
        var name = Change(update, "Name");
        Assert.Equal("Pres 4", name.GetProperty("old").GetString());
        Assert.Equal("Pres 4B", name.GetProperty("new").GetString());

        // Only the name changed, so only the name is recorded.
        Assert.Single(Changes(update).EnumerateObject());
    }

    [Fact]
    public async Task Password_changes_are_recorded_without_the_hash()
    {
        var admin = await _api.LoginAsAdminAsync();
        var plant = await _api.CreatePlantAsync(admin);
        var user = await _api.CreateUserAsync(admin, Role.Operator, plant.Id);

        var reset = await _api.SendAsync(
            HttpMethod.Post, $"/api/users/{user.Id}/reset-password", admin,
            new ResetPasswordRequest("Temporary-Password-2026"));
        Assert.Equal(HttpStatusCode.NoContent, reset.StatusCode);

        var entries = await EntriesForAsync(user.Id);
        var created = Assert.Single(entries, entry => entry.Action == AuditAction.Created);
        var update = Assert.Single(entries, entry => entry.Action == AuditAction.Updated);

        Assert.Equal(
            AuditInterceptor.MaskedValue,
            Change(created, "PasswordHash").GetProperty("new").GetString());
        Assert.Equal(
            AuditInterceptor.MaskedValue,
            Change(update, "PasswordHash").GetProperty("old").GetString());
        Assert.Equal(
            AuditInterceptor.MaskedValue,
            Change(update, "PasswordHash").GetProperty("new").GetString());
    }

    private async Task<List<AuditEntry>> EntriesForAsync(Guid entityId)
    {
        await using var dbContext = factory.CreateDbContext();

        return await dbContext.Set<AuditEntry>()
            .AsNoTracking()
            .Where(entry => entry.EntityId == entityId)
            .OrderBy(entry => entry.OccurredAt)
            .ToListAsync();
    }

    private async Task<Guid> CurrentUserIdAsync(AuthTokens tokens)
    {
        var response = await _api.SendAsync(HttpMethod.Get, "/api/auth/me", tokens);
        return (await IdentityTestClient.ReadAsync<CurrentUserResponse>(response)).Id;
    }

    private static JsonElement Changes(AuditEntry entry)
    {
        using var document = JsonDocument.Parse(entry.Changes);
        return document.RootElement.Clone();
    }

    private static JsonElement Change(AuditEntry entry, string property) =>
        Changes(entry).GetProperty(property);
}