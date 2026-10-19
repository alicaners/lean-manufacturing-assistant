using LeanAssistant.Application.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.JsonWebTokens;

namespace LeanAssistant.Api.Identity;

/// <summary>
/// Sign-in, session and password endpoints. They all stay open for a user who must change
/// their password, because they are the way out of that state.
/// </summary>
[ApiController]
[Route("api/auth")]
[AllowDuringPasswordChange]
public sealed class AuthController(AuthService authService, IUserRepository users) : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting(IdentityApiExtensions.LoginRateLimitPolicy)]
    [ProducesResponseType<AuthTokens>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<ActionResult<AuthTokens>> Login(
        LoginRequest request, CancellationToken cancellationToken)
    {
        var tokens = await authService.LoginAsync(request.UserName, request.Password, cancellationToken);

        if (tokens is null)
        {
            return Unauthorized();
        }

        return Ok(tokens);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType<AuthTokens>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthTokens>> Refresh(
        RefreshTokenRequest request, CancellationToken cancellationToken)
    {
        var tokens = await authService.RefreshAsync(request.RefreshToken, cancellationToken);

        if (tokens is null)
        {
            return Unauthorized();
        }

        return Ok(tokens);
    }

    [HttpPost("logout")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Logout(
        RefreshTokenRequest request, CancellationToken cancellationToken)
    {
        await authService.LogoutAsync(request.RefreshToken, cancellationToken);
        return NoContent();
    }

    [HttpGet("me")]
    [ProducesResponseType<CurrentUserResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CurrentUserResponse>> Me(CancellationToken cancellationToken)
    {
        if (CurrentUserId() is not { } userId)
        {
            return Unauthorized();
        }

        var user = await users.FindByIdAsync(userId, cancellationToken);
        if (user is null || !user.IsActive)
        {
            return Unauthorized();
        }

        return Ok(new CurrentUserResponse(
            user.Id, user.UserName, user.FullName, user.Role.ToString(), user.MustChangePassword));
    }

    /// <summary>
    /// Replaces the signed-in user's password. Closes every other session and returns
    /// new tokens for this device.
    /// </summary>
    [HttpPost("change-password")]
    [EnableRateLimiting(IdentityApiExtensions.LoginRateLimitPolicy)]
    [ProducesResponseType<AuthTokens>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status429TooManyRequests)]
    public async Task<ActionResult<AuthTokens>> ChangePassword(
        ChangePasswordRequest request, CancellationToken cancellationToken)
    {
        if (CurrentUserId() is not { } userId)
        {
            return Unauthorized();
        }

        var tokens = await authService.ChangePasswordAsync(
            userId, request.CurrentPassword, request.NewPassword, cancellationToken);

        if (tokens is null)
        {
            ModelState.AddModelError(nameof(request.CurrentPassword), "The current password is not correct.");
            return ValidationProblem(ModelState);
        }

        return Ok(tokens);
    }

    private Guid? CurrentUserId() =>
        Guid.TryParse(User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var id) ? id : null;
}

public sealed record CurrentUserResponse(
    Guid Id, string UserName, string FullName, string Role, bool MustChangePassword);