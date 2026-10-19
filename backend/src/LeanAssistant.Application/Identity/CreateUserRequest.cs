using FluentValidation;
using LeanAssistant.Domain.Identity;

namespace LeanAssistant.Application.Identity;

public sealed record CreateUserRequest(
    string UserName,
    string FullName,
    string Password,
    Role Role,
    Guid? FactoryId,
    Guid? LineId);

public sealed class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(request => request.UserName)
            .NotEmpty()
            .MaximumLength(User.UserNameMaxLength)
            .Matches("^[a-zA-Z0-9._-]+$")
            .WithMessage("User name can only contain letters, digits, '.', '_' and '-'.");

        RuleFor(request => request.FullName)
            .NotEmpty()
            .MaximumLength(User.FullNameMaxLength);

        RuleFor(request => request.Password)
            .NotEmpty()
            .MinimumLength(PasswordRules.MinimumLength)
            .MaximumLength(PasswordRules.MaximumLength);

        RuleFor(request => request.Role)
            .IsInEnum();

        // Without a plant a non-admin user would see nothing at all.
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