import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/widgets/error_view.dart';
import 'package:lean_assistant/core/widgets/primary_button.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ErrorView', () {
    testWidgets('shows retry button and calls onRetry when tapped', (
      tester,
    ) async {
      var retried = false;

      await tester.pumpApp(ErrorView(onRetry: () => retried = true));
      await tester.tap(find.text('Tekrar dene'));

      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpApp(const ErrorView());

      expect(find.text('Bir şeyler ters gitti'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsNothing);
    });
  });

  group('PrimaryButton', () {
    testWidgets('is disabled and shows a spinner while loading', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpApp(
        PrimaryButton(
          label: 'Kaydet',
          onPressed: () => pressed = true,
          isLoading: true,
        ),
      );
      await tester.tap(find.byType(FilledButton));

      expect(pressed, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Kaydet'), findsNothing);
    });
  });
}
