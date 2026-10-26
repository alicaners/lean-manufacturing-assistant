using System.Diagnostics;
using LeanAssistant.Api.Identity;
using LeanAssistant.Application.Organization;
using LeanAssistant.Domain.Identity;
using LeanAssistant.Domain.Organization;
using Microsoft.AspNetCore.Mvc;

namespace LeanAssistant.Api.Organization;

/// <summary>
/// The organization tree: plants, departments, lines and machines.
/// Every signed-in user can read their own plant; only admins can change it.
/// Records of another plant answer 404, as if they did not exist.
/// </summary>
[ApiController]
[Route("api")]
public sealed class OrganizationController(OrganizationService organization) : ControllerBase
{
    // ---------- Plants ----------

    [HttpGet("factories")]
    [ProducesResponseType<FactoryResponse[]>(StatusCodes.Status200OK)]
    public async Task<ActionResult<FactoryResponse[]>> ListFactories(CancellationToken cancellationToken) =>
        Ok(await organization.ListFactoriesAsync(cancellationToken));

    [HttpGet("factories/{id:guid}")]
    [ProducesResponseType<FactoryResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FactoryResponse>> GetFactory(Guid id, CancellationToken cancellationToken) =>
        ToResponse(await organization.GetFactoryAsync(id, cancellationToken));

    /// <summary>The whole plant in one response, served from the cache when possible.</summary>
    [HttpGet("factories/{id:guid}/tree")]
    [ProducesResponseType<FactoryTreeResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FactoryTreeResponse>> GetFactoryTree(
        Guid id, CancellationToken cancellationToken) =>
        ToResponse(await organization.GetTreeAsync(id, cancellationToken));

    [HttpPost("factories")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<FactoryResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<FactoryResponse>> CreateFactory(
        CreateFactoryRequest request, CancellationToken cancellationToken)
    {
        var result = await organization.CreateFactoryAsync(request, cancellationToken);
        if (result.Error is { } error)
        {
            return ToProblem(error);
        }

        return CreatedAtAction(nameof(GetFactory), new { id = result.Value!.Id }, result.Value);
    }

    [HttpPut("factories/{id:guid}")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<FactoryResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FactoryResponse>> RenameFactory(
        Guid id, NameRequest request, CancellationToken cancellationToken) =>
        ToResponse(await organization.RenameFactoryAsync(id, request, cancellationToken));

    // ---------- Departments ----------

    [HttpGet("factories/{factoryId:guid}/departments")]
    [ProducesResponseType<DepartmentResponse[]>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<DepartmentResponse[]>> ListDepartments(
        Guid factoryId, CancellationToken cancellationToken) =>
        ToResponse(await organization.ListDepartmentsAsync(factoryId, cancellationToken));

    [HttpGet("departments/{id:guid}")]
    [ProducesResponseType<DepartmentResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<DepartmentResponse>> GetDepartment(Guid id, CancellationToken cancellationToken) =>
        ToResponse(await organization.GetDepartmentAsync(id, cancellationToken));

    [HttpPost("factories/{factoryId:guid}/departments")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<DepartmentResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<DepartmentResponse>> CreateDepartment(
        Guid factoryId, NameRequest request, CancellationToken cancellationToken)
    {
        var result = await organization.CreateDepartmentAsync(factoryId, request, cancellationToken);
        if (result.Error is { } error)
        {
            return ToProblem(error);
        }

        return CreatedAtAction(nameof(GetDepartment), new { id = result.Value!.Id }, result.Value);
    }

    [HttpPut("departments/{id:guid}")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<DepartmentResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<DepartmentResponse>> RenameDepartment(
        Guid id, NameRequest request, CancellationToken cancellationToken) =>
        ToResponse(await organization.RenameDepartmentAsync(id, request, cancellationToken));

    // ---------- Lines ----------

    [HttpGet("departments/{departmentId:guid}/lines")]
    [ProducesResponseType<LineResponse[]>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<LineResponse[]>> ListLines(
        Guid departmentId, CancellationToken cancellationToken) =>
        ToResponse(await organization.ListLinesAsync(departmentId, cancellationToken));

    [HttpGet("lines/{id:guid}")]
    [ProducesResponseType<LineResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<LineResponse>> GetLine(Guid id, CancellationToken cancellationToken) =>
        ToResponse(await organization.GetLineAsync(id, cancellationToken));

    [HttpPost("departments/{departmentId:guid}/lines")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<LineResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<LineResponse>> CreateLine(
        Guid departmentId, NameRequest request, CancellationToken cancellationToken)
    {
        var result = await organization.CreateLineAsync(departmentId, request, cancellationToken);
        if (result.Error is { } error)
        {
            return ToProblem(error);
        }

        return CreatedAtAction(nameof(GetLine), new { id = result.Value!.Id }, result.Value);
    }

    [HttpPut("lines/{id:guid}")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<LineResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<LineResponse>> RenameLine(
        Guid id, NameRequest request, CancellationToken cancellationToken) =>
        ToResponse(await organization.RenameLineAsync(id, request, cancellationToken));

    // ---------- Machines ----------

    [HttpGet("lines/{lineId:guid}/machines")]
    [ProducesResponseType<MachineResponse[]>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MachineResponse[]>> ListMachines(
        Guid lineId, CancellationToken cancellationToken) =>
        ToResponse(await organization.ListMachinesAsync(lineId, cancellationToken));

    [HttpGet("machines/{id:guid}")]
    [ProducesResponseType<MachineResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MachineResponse>> GetMachine(Guid id, CancellationToken cancellationToken) =>
        ToResponse(await organization.GetMachineAsync(id, cancellationToken));

    /// <summary>What the app calls after scanning a machine's QR label.</summary>
    [HttpGet("machines/by-qr/{qrCode:length(22)}")]
    [ProducesResponseType<MachineResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MachineResponse>> FindMachineByQrCode(
        string qrCode, CancellationToken cancellationToken) =>
        ToResponse(await organization.FindMachineByQrCodeAsync(qrCode, cancellationToken));

    [HttpPost("lines/{lineId:guid}/machines")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<MachineResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<MachineResponse>> CreateMachine(
        Guid lineId, CreateMachineRequest request, CancellationToken cancellationToken)
    {
        var result = await organization.CreateMachineAsync(lineId, request, cancellationToken);
        if (result.Error is { } error)
        {
            return ToProblem(error);
        }

        return CreatedAtAction(nameof(GetMachine), new { id = result.Value!.Id }, result.Value);
    }

    [HttpPut("machines/{id:guid}")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<MachineResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MachineResponse>> RenameMachine(
        Guid id, NameRequest request, CancellationToken cancellationToken) =>
        ToResponse(await organization.RenameMachineAsync(id, request, cancellationToken));

    /// <summary>For a lost or copied label. The old label stops working.</summary>
    [HttpPost("machines/{id:guid}/regenerate-qr")]
    [RequirePermission(Permission.ManageOrganization)]
    [ProducesResponseType<MachineResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MachineResponse>> RegenerateQrCode(Guid id, CancellationToken cancellationToken) =>
        ToResponse(await organization.RegenerateQrCodeAsync(id, cancellationToken));

    private ActionResult<T> ToResponse<T>(OrganizationResult<T> result)
        where T : class =>
        result.Error is { } error ? ToProblem(error) : Ok(result.Value);

    private ActionResult ToProblem(OrganizationError error) => error switch
    {
        OrganizationError.NotFound => NotFound(),
        OrganizationError.DuplicateCode => Problem(
            statusCode: StatusCodes.Status409Conflict,
            title: "This code is already in use."),
        OrganizationError.DuplicateName => Problem(
            statusCode: StatusCodes.Status409Conflict,
            title: "This name is already in use here."),
        OrganizationError.SystemAdminOnly => Problem(
            statusCode: StatusCodes.Status403Forbidden,
            title: "Only a system admin can create plants."),
        _ => throw new UnreachableException()
    };
}