import 'package:flutter/material.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';

/// Placeholder until the real sign-in form is built in stage 4.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: EmptyView(message: l10n.loginComingSoon, icon: Icons.lock_outline),
    );
  }
}
