import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/app.dart';

void main() {
  testWidgets('App starts and shows the app name', (tester) async {
    await tester.pumpWidget(const LeanAssistantApp());

    expect(find.text('Yalın Üretim Asistanı'), findsOneWidget);
  });
}
