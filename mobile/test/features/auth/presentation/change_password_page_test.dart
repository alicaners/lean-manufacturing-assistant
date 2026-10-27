import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/app/di/injection.dart';
import 'package:lean_assistant/core/forms/submit_state.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/change_password_cubit.dart';
import 'package:lean_assistant/features/auth/presentation/change_password_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth.dart';
import '../../../helpers/pump_app.dart';

class _MockChangePasswordCubit extends MockCubit<SubmitState>
    implements ChangePasswordCubit {}

void main() {
  late _MockChangePasswordCubit cubit;

  setUp(() {
    cubit = _MockChangePasswordCubit();
    when(() => cubit.state).thenReturn(const SubmitIdle());
    getIt.registerFactory<ChangePasswordCubit>(() => cubit);
  });

  tearDown(getIt.reset);

  testWidgets('checks the new password before sending it', (tester) async {
    await tester.pumpApp(
      BlocProvider<AuthBloc>.value(
        value: authBlocIn(const AuthSignedIn(testUserWithTemporaryPassword)),
        child: const ChangePasswordPage(),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mevcut şifre'),
      'Temporary-Password-1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Yeni şifre'),
      'short',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Yeni şifre (tekrar)'),
      'different',
    );
    await tester.ensureVisible(find.text('Şifreyi değiştir'));
    await tester.tap(find.text('Şifreyi değiştir'));
    await tester.pump();

    expect(find.text('Şifre en az 12 karakter olmalı.'), findsOneWidget);
    expect(find.text('Şifreler eşleşmiyor.'), findsOneWidget);
    verifyNever(
      () => cubit.submit(
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    );
  });
}
