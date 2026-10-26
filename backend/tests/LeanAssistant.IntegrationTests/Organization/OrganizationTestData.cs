using System.Net;
using LeanAssistant.Application.Identity;
using LeanAssistant.Application.Organization;
using LeanAssistant.IntegrationTests.Identity;

namespace LeanAssistant.IntegrationTests.Organization;

/// <summary>Builds organization records through the API, the way an admin would.</summary>
internal static class OrganizationTestData
{
    public static async Task<FactoryResponse> CreatePlantAsync(this IdentityTestClient api, AuthTokens systemAdmin) =>
        await PostAsync<FactoryResponse>(
            api, systemAdmin, "/api/factories", new CreateFactoryRequest("Test Plant", NewCode("P")));

    /// <summary>Creates a department, a line and a machine under the plant.</summary>
    public static async Task<MachineResponse> CreateMachineAsync(
        this IdentityTestClient api, AuthTokens caller, Guid plantId)
    {
        var department = await PostAsync<DepartmentResponse>(
            api, caller, $"/api/factories/{plantId}/departments", new NameRequest("Pres"));
        var line = await PostAsync<LineResponse>(
            api, caller, $"/api/departments/{department.Id}/lines", new NameRequest("Hat 1"));

        return await PostAsync<MachineResponse>(
            api, caller, $"/api/lines/{line.Id}/machines", new CreateMachineRequest("Pres 4", NewCode("M")));
    }

    // Every test makes its own plants, so tests sharing one database never collide.
    public static string NewCode(string prefix) =>
        prefix + Guid.NewGuid().ToString("N")[..10].ToUpperInvariant();

    private static async Task<T> PostAsync<T>(IdentityTestClient api, AuthTokens caller, string url, object body)
        where T : class
    {
        var response = await api.SendAsync(HttpMethod.Post, url, caller, body);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return await IdentityTestClient.ReadAsync<T>(response);
    }
}