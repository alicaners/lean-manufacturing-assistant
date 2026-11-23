import 'package:flutter/widgets.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';

/// Checks for form fields. Each returns an error message, or null when valid.
abstract final class Validators {
  static FormFieldValidator<String> required(AppLocalizations l10n) {
    return (value) =>
        value == null || value.trim().isEmpty ? l10n.fieldRequired : null;
  }

  /// A password of at least [minLength] characters.
  static FormFieldValidator<String> password(
    AppLocalizations l10n, {
    required int minLength,
  }) {
    return (value) {
      final password = value ?? '';

      if (password.isEmpty) return l10n.fieldRequired;
      if (password.length < minLength) {
        return l10n.changePasswordTooShort(minLength);
      }
      return null;
    };
  }
}
