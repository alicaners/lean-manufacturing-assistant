using System.Globalization;
using FluentValidation;
using LeanAssistant.Application.Identity;
using Microsoft.Extensions.DependencyInjection;

namespace LeanAssistant.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        // API messages are always English, regardless of the server's OS language.
        // User-facing translations are the mobile app's responsibility.
        ValidatorOptions.Global.LanguageManager.Culture = new CultureInfo("en");

        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        services.AddScoped<AuthService>();
        services.AddScoped<AdminBootstrapper>();
        services.AddScoped<UserManagementService>();

        return services;
    }
}