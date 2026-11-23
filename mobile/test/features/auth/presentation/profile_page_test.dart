import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';
import 'package:lean_assistant/features/auth/presentation/profile_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows who is signed in', (tester) async {
    await tester.pumpApp(
      BlocProvider<AuthBloc>.value(
        value: authBlocIn(const AuthSignedIn(testUser)),
        child: const ProfilePage(),
      ),
    );

    expect(find.text('Demo Operatör'), findsOneWidget);
    expect(find.text('demo.operator · Operatör'), findsOneWidget);
  });

  testWidgets('signs out', (tester) async {
    final authBloc = authBlocIn(const AuthSignedIn(testUser));

    await tester.pumpApp(
      BlocProvider<AuthBloc>.value(value: authBloc, child: const ProfilePage()),
    );
    await tester.ensureVisible(find.text('Çıkış yap'));
    await tester.tap(find.text('Çıkış yap'));

    verify(() => authBloc.add(const AuthSignOutRequested())).called(1);
  });
}
