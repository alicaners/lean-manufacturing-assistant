using FluentValidation;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public sealed record UpdateUserAccessRequest(Role Role, Guid? FactoryId, Guid? LineId);

public sealed class UpdateUserAccessRequestValidator : AbstractValidator<UpdateUserAccessRequest>
{
    public UpdateUserAccessRequestValidator()
    {
        RuleFor(request => request.Role)
            .IsInEnum();

        RuleFor(request => request.FactoryId)
            .NotNull()
            .WithMessage("A plant is required for every role except Admin.")
            .When(request => request.Role != Role.Admin);

        RuleFor(request => request.FactoryId)
            .NotEqual(Guid.Empty);

        RuleFor(request => request.LineId)
            .Null()
            .WithMessage("A line can only be assigned together with its plant.")
            .When(request => request.FactoryId is null);

        RuleFor(request => request.LineId)
            .NotEqual(Guid.Empty);
    }
}