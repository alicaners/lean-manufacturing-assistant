using FluentValidation;
using LeanAssistant.Domain.Organization;

namespace LeanAssistant.Application.Organization;

public sealed record CreateFactoryRequest(string Name, string Code);

public sealed class CreateFactoryRequestValidator : AbstractValidator<CreateFactoryRequest>
{
    public CreateFactoryRequestValidator()
    {
        RuleFor(request => request.Name)
            .NotEmpty()
            .MaximumLength(Factory.NameMaxLength);

        RuleFor(request => request.Code)
            .NotEmpty()
            .MaximumLength(Factory.CodeMaxLength)
            .Matches("^[A-Za-z0-9-]+$")
            .WithMessage("Code can only contain letters, digits and '-'.");
    }
}