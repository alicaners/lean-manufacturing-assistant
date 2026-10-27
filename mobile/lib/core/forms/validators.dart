import 'package:flutter/widgets.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';

/// Checks for form fields. Each returns an error message, or null when valid.
abstract final class Validators {
  static FormFieldValidator<String> required(AppLocalizations l10n) {
    return (value) =>
        value == null || value.trim().isEmpty ? l10n.fieldRequired : null;
  }
}
