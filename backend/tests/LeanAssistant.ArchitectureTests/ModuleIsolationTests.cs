using System.Reflection;
using LeanAssistant.Domain.SharedKernel;
using NetArchTest.Rules;

namespace LeanAssistant.ArchitectureTests;

public class ModuleIsolationTests
{
    private static readonly string[] Modules =
        ["Identity", "Organization", "Andon", "Kaizen", "FiveS"];

    private static readonly Assembly[] Layers =
    [
        typeof(Entity).Assembly,
        typeof(LeanAssistant.Application.DependencyInjection).Assembly,
        typeof(LeanAssistant.Infrastructure.DependencyInjection).Assembly
    ];

    [Theory]
    [InlineData("Identity")]
    [InlineData("Organization")]
    [InlineData("Andon")]
    [InlineData("Kaizen")]
    [InlineData("FiveS")]
    public void Module_does_not_depend_on_other_modules(string module)
    {
        var otherModuleNamespaces = Modules
            .Where(other => other != module)
            .SelectMany(other => Layers.Select(layer => $"{layer.GetName().Name}.{other}"))
            .ToArray();

        foreach (var layer in Layers)
        {
            var result = Types.InAssembly(layer)
                .That()
                .ResideInNamespace($"{layer.GetName().Name}.{module}")
                .ShouldNot()
                .HaveDependencyOnAny(otherModuleNamespaces)
                .GetResult();

            Assert.True(
                result.IsSuccessful,
                $"{module} module depends on another module in: " +
                string.Join(", ", result.FailingTypeNames ?? []));
        }
    }
}