using LeanAssistant.Application.Identity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.JsonWebTokens;

namespace LeanAssistant.Api.Identity;

[ApiController]
[Route("api/auth")]
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
        var subject = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        if (!Guid.TryParse(subject, out var userId))
        {
            return Unauthorized();
        }

        var user = await users.FindByIdAsync(userId, cancellationToken);
        if (user is null || !user.IsActive)
        {
            return Unauthorized();
        }

        return Ok(new CurrentUserResponse(user.Id, user.UserName, user.FullName, user.Role.ToString()));
    }
}

public sealed record CurrentUserResponse(Guid Id, string UserName, string FullName, string Role);