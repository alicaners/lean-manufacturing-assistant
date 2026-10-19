using FluentValidation;

namespace LeanAssistant.Application.Identity;

public sealed record ChangePasswordRequest(string CurrentPassword, string NewPassword);

public sealed class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequest>
{
    public ChangePasswordRequestValidator()
    {
        RuleFor(request => request.CurrentPassword)
            .NotEmpty()
            .MaximumLength(PasswordRules.MaximumLength);

        RuleFor(request => request.NewPassword)
            .NotEmpty()
            .MinimumLength(PasswordRules.MinimumLength)
            .MaximumLength(PasswordRules.MaximumLength)
            .NotEqual(request => request.CurrentPassword)
            .WithMessage("The new password must be different from the current one.");
    }
}