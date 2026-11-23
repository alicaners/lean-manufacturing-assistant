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
    getIt.registerFactory<LoginCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  /// The sign-in page on a phone-sized screen, in the given state.
  Future<void> pumpLoginPage(WidgetTester tester, SubmitState state) async {
    tester.view
      ..physicalSize = const Size(780, 1688)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    when(() => cubit.state).thenReturn(state);
    await tester.pumpApp(const LoginPage());
  }

  testWidgets('sign-in page', (tester) async {
    await pumpLoginPage(tester, const SubmitIdle());

    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_page.png'),
    );
  });

  testWidgets('sign-in page after a wrong password', (tester) async {
    await pumpLoginPage(tester, const SubmitFailed(UnauthorizedFailure()));

    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_page_wrong_credentials.png'),
    );
  });
}
