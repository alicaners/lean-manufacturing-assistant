import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/core/error/failure.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/splash_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth.dart';
import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpSplash(WidgetTester tester, MockAuthBloc bloc) {
    return tester.pumpApp(
      BlocProvider<AuthBloc>.value(value: bloc, child: const SplashPage()),
    );
  }

  testWidgets('shows progress while the session is checked', (tester) async {
    await pumpSplash(tester, authBlocIn(const AuthUnknown()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Oturum kontrol ediliyor…'), findsOneWidget);
  });

  testWidgets('offers a retry when the server cannot be reached', (
    tester,
  ) async {
    final bloc = authBlocIn(const AuthUnavailable(NetworkFailure()));
    await pumpSplash(tester, bloc);

    expect(
      find.text('Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Tekrar dene'));

    verify(() => bloc.add(const AuthCheckRequested())).called(1);
  });
}
