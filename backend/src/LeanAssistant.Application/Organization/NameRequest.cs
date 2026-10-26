using FluentValidation;
using LeanAssistant.Domain.Organization;

namespace LeanAssistant.Application.Organization;

/// <summary>Body of every request that only carries a name: create a department or line, rename anything.</summary>
public sealed record NameRequest(string Name);

public sealed class NameRequestValidator : AbstractValidator<NameRequest>
{
    public NameRequestValidator()
    {
        // Every level of the tree allows the same name length.
        RuleFor(request => request.Name)
            .NotEmpty()
            .MaximumLength(Factory.NameMaxLength);
    }
}