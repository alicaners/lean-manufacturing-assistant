namespace LeanAssistant.IntegrationTests;

/// <summary>
/// Every test class marked with [Collection(ApiCollection.Name)] shares one
/// <see cref="ApiFactory"/>: one database container and one running app.
/// </summary>
[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "Api";
}