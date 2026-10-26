using FluentValidation;
using LeanAssistant.Domain.Organization;

namespace LeanAssistant.Application.Organization;

public sealed record CreateMachineRequest(string Name, string Code);

public sealed class CreateMachineRequestValidator : AbstractValidator<CreateMachineRequest>
{
    public CreateMachineRequestValidator()
    {
        RuleFor(request => request.Name)
            .NotEmpty()
            .MaximumLength(Machine.NameMaxLength);

        RuleFor(request => request.Code)
            .NotEmpty()
            .MaximumLength(Machine.CodeMaxLength)
            .Matches("^[A-Za-z0-9-]+$")
            .WithMessage("Code can only contain letters, digits and '-'.");
    }
}