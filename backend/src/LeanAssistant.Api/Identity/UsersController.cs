using System.Diagnostics;
using LeanAssistant.Application.Identity;
using LeanAssistant.Domain.Identity;
using Microsoft.AspNetCore.Mvc;

namespace LeanAssistant.Api.Identity;

/// <summary>
/// User management for admins. A plant admin sees and manages only their own plant;
/// a user of another plant answers 404, as if it did not exist.
/// </summary>
[ApiController]
[Route("api/users")]
[RequirePermission(Permission.ManageUsers)]
public sealed class UsersController(UserManagementService userManagement) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<IReadOnlyList<UserResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<UserResponse>>> List(CancellationToken cancellationToken) =>
        Ok(await userManagement.ListAsync(cancellationToken));

    [HttpGet("{id:guid}")]
    [ProducesResponseType<UserResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> Get(Guid id, CancellationToken cancellationToken)
    {
        var user = await userManagement.GetAsync(id, cancellationToken);
        if (user is null)
        {
            return NotFound();
        }

        return Ok(user);
    }

    [HttpPost]
    [ProducesResponseType<UserResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UserResponse>> Create(
        CreateUserRequest request, CancellationToken cancellationToken)
    {
        var result = await userManagement.CreateAsync(request, cancellationToken);
        if (result.Error is { } error)
        {
            return ToProblem(error);
        }

        return CreatedAtAction(nameof(Get), new { id = result.Value!.Id }, result.Value);
    }

    /// <summary>Changes role and scope together. Signs the user out of every device.</summary>
    [HttpPut("{id:guid}/access")]
    [ProducesResponseType<UserResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserResponse>> UpdateAccess(
        Guid id, UpdateUserAccessRequest request, CancellationToken cancellationToken)
    {
        var result = await userManagement.UpdateAccessAsync(id, request, cancellationToken);
        if (result.Error is { } error)
        {
            return ToProblem(error);
        }

        return Ok(result.Value);
    }

    [HttpPost("{id:guid}/deactivate")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken cancellationToken)
    {
        var result = await userManagement.DeactivateAsync(id, cancellationToken);
        return result.Error is { } error ? ToProblem(error) : NoContent();
    }

    [HttpPost("{id:guid}/activate")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Activate(Guid id, CancellationToken cancellationToken)
    {
        var result = await userManagement.ActivateAsync(id, cancellationToken);
        return result.Error is { } error ? ToProblem(error) : NoContent();
    }

    /// <summary>Sets a temporary password. Signs the user out of every device.</summary>
    [HttpPost("{id:guid}/reset-password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ResetPassword(
        Guid id, ResetPasswordRequest request, CancellationToken cancellationToken)
    {
        var result = await userManagement.ResetPasswordAsync(id, request, cancellationToken);
        return result.Error is { } error ? ToProblem(error) : NoContent();
    }

    private ActionResult ToProblem(UserManagementError error) => error switch
    {
        UserManagementError.NotFound => NotFound(),
        UserManagementError.UserNameTaken => Problem(
            statusCode: StatusCodes.Status409Conflict,
            title: "This user name is already in use."),
        UserManagementError.OutsideScope => Problem(
            statusCode: StatusCodes.Status403Forbidden,
            title: "You can only manage users of your own plant."),
        UserManagementError.SelfChange => Problem(
            statusCode: StatusCodes.Status400BadRequest,
            title: "You cannot change your own access or deactivate yourself."),
        _ => throw new UnreachableException()
    };
}