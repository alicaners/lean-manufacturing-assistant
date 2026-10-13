using System.Reflection;
using LeanAssistant.Api.ErrorHandling;
using LeanAssistant.Domain.SharedKernel;
using NetArchTest.Rules;

namespace LeanAssistant.ArchitectureTests;

public class LayerDependencyTests
{
    private const string ApplicationNamespace = "LeanAssistant.Application";
    private const string InfrastructureNamespace = "LeanAssistant.Infrastructure";
    private const string ApiNamespace = "LeanAssistant.Api";

    private static readonly Assembly DomainAssembly = typeof(Entity).Assembly;
    private static readonly Assembly ApplicationAssembly =
        typeof(LeanAssistant.Application.DependencyInjection).Assembly;
    private static readonly Assembly InfrastructureAssembly =
        typeof(LeanAssistant.Infrastructure.DependencyInjection).Assembly;

    [Fact]
    public void Domain_does_not_depend_on_other_layers_or_frameworks()
    {
        var result = Types.InAssembly(DomainAssembly)
            .ShouldNot()
            .HaveDependencyOnAny(
                ApplicationNamespace,
                InfrastructureNamespace,
                ApiNamespace,
                "Microsoft.EntityFrameworkCore",
                "Microsoft.AspNetCore",
                "Npgsql",
                "Serilog",
                "FluentValidation")
            .GetResult();

        Assert.True(result.IsSuccessful, Describe(result));
    }

    [Fact]
    public void Application_does_not_depend_on_infrastructure_or_api()
    {
        var result = Types.InAssembly(ApplicationAssembly)
            .ShouldNot()
            .HaveDependencyOnAny(
                InfrastructureNamespace,
                ApiNamespace,
                "Microsoft.EntityFrameworkCore",
                "Microsoft.AspNetCore",
                "Npgsql")
            .GetResult();

        Assert.True(result.IsSuccessful, Describe(result));
    }

    [Fact]
    public void Infrastructure_does_not_depend_on_api()
    {
        var result = Types.InAssembly(InfrastructureAssembly)
            .ShouldNot()
            .HaveDependencyOn(ApiNamespace)
            .GetResult();

        Assert.True(result.IsSuccessful, Describe(result));
    }

    [Fact]
    public void Api_assembly_is_loaded()
    {
        // Guards against the Api project being silently removed from this test project.
        Assert.NotNull(typeof(GlobalExceptionHandler).Assembly);
    }

    private static string Describe(TestResult result) =>
        result.IsSuccessful
            ? string.Empty
            : "Forbidden dependency in: " + string.Join(", ", result.FailingTypeNames ?? []);
}