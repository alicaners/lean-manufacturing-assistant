import 'package:bloc_test/bloc_test.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';
import 'package:lean_assistant/features/auth/presentation/auth_bloc.dart';
import 'package:lean_assistant/features/auth/presentation/auth_event.dart';
import 'package:lean_assistant/features/auth/presentation/auth_state.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

const testUser = CurrentUser(
  id: '01a177de-2504-7c0a-a458-d380e5314fba',
  userName: 'demo.operator',
  fullName: 'Demo Operatör',
  role: UserRole.operator,
  mustChangePassword: false,
);

/// An AuthBloc that stays in [state].
MockAuthBloc authBlocIn(AuthState state) {
  final bloc = MockAuthBloc();
  whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
  return bloc;
}
