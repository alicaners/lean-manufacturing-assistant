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

/// A user whose password an admin has just set.
const testUserWithTemporaryPassword = CurrentUser(
  id: '01a177de-2504-7c0a-a458-d380e5314fbb',
  userName: 'new.operator',
  fullName: 'Yeni Operatör',
  role: UserRole.operator,
  mustChangePassword: true,
);

/// A user who may manage users and the organization.
const testAdmin = CurrentUser(
  id: '01a177de-2504-7c0a-a458-d380e5314fbc',
  userName: 'demo.admin',
  fullName: 'Demo Admin',
  role: UserRole.admin,
  mustChangePassword: false,
);

/// An AuthBloc that stays in [state].
MockAuthBloc authBlocIn(AuthState state) {
  final bloc = MockAuthBloc();
  whenListen(bloc, const Stream<AuthState>.empty(), initialState: state);
  return bloc;
}
