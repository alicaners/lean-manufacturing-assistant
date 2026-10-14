import 'package:flutter/material.dart';

/// Centered progress indicator with an optional message.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
