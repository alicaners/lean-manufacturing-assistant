import 'package:flutter/material.dart';

/// Labeled text input that works inside a [Form].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.errorText,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  /// Lets password managers fill the field, e.g. [AutofillHints.username].
  final Iterable<String>? autofillHints;

  /// An error from the server, shown even when [validator] passes.
  final String? errorText;

  /// Called when the user presses the keyboard's action button.
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autofillHints: autofillHints,
      forceErrorText: errorText,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(labelText: label),
    );
  }
}
