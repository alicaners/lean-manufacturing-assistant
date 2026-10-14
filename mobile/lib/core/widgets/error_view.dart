import 'package:flutter/material.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';

/// Centered error state with an optional action button.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.actionLabel,
  });

  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  /// Label of the action button. Defaults to "Try again".
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final retry = onRetry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.errorGenericTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? l10n.errorGenericMessage,
              textAlign: TextAlign.center,
            ),
            if (retry != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel ?? l10n.commonRetry,
                onPressed: retry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
