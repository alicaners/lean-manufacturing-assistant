import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/app.dart';
import 'package:lean_assistant/app/router/app_router.dart';
import 'package:lean_assistant/features/dashboard/presentation/home_page.dart';

void main() {
  testWidgets('App starts on the home page', (tester) async {
    await tester.pumpWidget(LeanAssistantApp(router: createRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
