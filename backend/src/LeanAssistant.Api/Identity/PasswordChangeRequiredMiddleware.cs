using LeanAssistant.Infrastructure.Identity;
using Microsoft.AspNetCore.Mvc;

namespace LeanAssistant.Api.Identity;

/// <summary>
/// Stops every request of a user who must change their password, except on endpoints
/// marked with <see cref="AllowDuringPasswordChangeAttribute"/>.
/// Closed by default, so a new endpoint cannot forget this check.
/// </summary>
public sealed class PasswordChangeRequiredMiddleware(
    RequestDelegate next,
    IProblemDetailsService problemDetailsService)
{
    /// <summary>Lets the app recognize this 403 and open the change-password screen.</summary>
    public const string ErrorCode = "password_change_required";

    public async Task InvokeAsync(HttpContext context)
    {
        var mustChangePassword = context.User.HasClaim(JwtAccessTokenIssuer.PasswordChangeClaim, "true");
        var allowed = context.GetEndpoint()?.Metadata
            .GetMetadata<AllowDuringPasswordChangeAttribute>() is not null;

        if (mustChangePassword && !allowed)
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;

            await problemDetailsService.WriteAsync(new ProblemDetailsContext
            {
                HttpContext = context,
                ProblemDetails = new ProblemDetails
                {
                    Status = StatusCodes.Status403Forbidden,
                    Title = "You must change your password before continuing.",
                    Extensions = { ["code"] = ErrorCode }
                }
            });

            return;
        }

        await next(context);
    }
}