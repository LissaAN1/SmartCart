import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/session/ui/bloc/session_event.dart';
import 'package:smartcart/features/session/ui/bloc/session_state.dart';

import '../support/fakes.dart';

Matcher _status(SessionStatus status) =>
    isA<SessionState>().having((s) => s.status, 'status', status);

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  test('sin sesión guardada queda unauthenticated', () async {
    final bloc = env.sessionBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(SessionStatus.loading),
        _status(SessionStatus.unauthenticated),
      ]),
    );
    bloc.add(SessionStarted());
    await expectation;
  });

  test('con sesión guardada recupera el perfil', () async {
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    env.profiles.stored = profileWith({UserRole.cliente});
    final bloc = env.sessionBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(SessionStatus.loading),
        isA<SessionState>()
            .having((s) => s.status, 'status', SessionStatus.authenticated)
            .having((s) => s.profile?.fullName, 'name', 'Ana María Gómez'),
      ]),
    );
    bloc.add(SessionStarted());
    await expectation;
  });

  test('si no se puede leer el perfil no confía en la sesión guardada', () async {
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    final bloc = env.sessionBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(SessionStatus.loading),
        _status(SessionStatus.unauthenticated),
      ]),
    );
    bloc.add(SessionStarted());
    await expectation;
  });

  test('SignOutRequested cierra la sesión y queda unauthenticated', () async {
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    final bloc = env.sessionBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([_status(SessionStatus.unauthenticated)]),
    );
    bloc.add(SignOutRequested());
    await expectation;
    expect(env.auth.signOutCalls, 1);
    expect(env.auth.currentUser(), isNull);
  });
}
