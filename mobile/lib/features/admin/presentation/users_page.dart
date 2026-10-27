import 'package:flutter/material.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';

/// User management for admins. Filled in by the next step (#9).
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.usersTitle)),
      body: EmptyView(
        message: l10n.usersComingSoon,
        icon: Icons.group_outlined,
      ),
    );
  }
}
