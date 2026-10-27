import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/auth/presentation/login_cubit.dart';
import 'package:lean_assistant/features/auth/presentation/login_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockLoginCubit extends MockCubit<SubmitState> implements LoginCubit {}

void main() {
  late _MockLoginCubit cubit;

  setUp(() {
    cubit = _MockLoginCubit();
    when(() => cubit.state).thenReturn(const SubmitIdle());
    when(
      () => cubit.submit(
        userName: any(named: 'userName'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    getIt.registerFactory<LoginCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  Future<void> tapSignIn(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Giriş yap'));
    await tester.tap(find.text('Giriş yap'));
    await tester.pump();
  }

  testWidgets('asks for both fields before signing in', (tester) async {
    await tester.pumpApp(const LoginPage());

    await tapSignIn(tester);

    expect(find.text('Bu alan zorunludur.'), findsNWidgets(2));
    verifyNever(
      () => cubit.submit(
        userName: any(named: 'userName'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('signs in with what was typed', (tester) async {
    await tester.pumpApp(const LoginPage());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kullanıcı adı'),
      'demo.operator',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şifre'),
      'Demo-Password-1',
    );
    await tapSignIn(tester);

    verify(
      () =>
          cubit.submit(userName: 'demo.operator', password: 'Demo-Password-1'),
    ).called(1);
  });

  testWidgets('explains a wrong user name or password', (tester) async {
    when(() => cubit.state)
        .thenReturn(const SubmitFailed(UnauthorizedFailure()));

    await tester.pumpApp(const LoginPage());

    expect(find.text('Kullanıcı adı veya şifre hatalı.'), findsOneWidget);
  });
}
