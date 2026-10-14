import 'package:flutter/material.dart';
import 'package:lean_assistant/core/l10n/l10n.dart';
import 'package:lean_assistant/core/widgets/empty_view.dart';

/// Temporary home page until the real dashboard is built.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: EmptyView(
        message: l10n.homeEmptyMessage,
        icon: Icons.precision_manufacturing_outlined,
      ),
    );
  }
}
