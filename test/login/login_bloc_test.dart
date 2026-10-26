import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/login/ui/bloc/login_event.dart';
import 'package:smartcart/features/login/ui/bloc/login_state.dart';

import '../support/fakes.dart';

Matcher _status(LoginStatus status) =>
    isA<LoginState>().having((s) => s.status, 'status', status);

LoginSubmitted _event(UserRole role) => LoginSubmitted(
      email: 'ana@correo.com',
      password: 'clave1234',
      role: role,
    );

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  test('emite loading y luego success con el perfil', () async {
    env.profiles.stored = profileWith({UserRole.cliente});
    final bloc = env.loginBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.success)
            .having((s) => s.profile?.id, 'profile id', 'u1'),
      ]),
    );
    bloc.add(_event(UserRole.cliente));
    await expectation;
  });

  test('emite failure con el mensaje de AuthFailure', () async {
    env.auth.signInError = const AuthFailure('El correo o la contraseña no son correctos.');
    final bloc = env.loginBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(LoginStatus.loading),
        isA<LoginState>()
            .having((s) => s.status, 'status', LoginStatus.failure)
            .having((s) => s.errorMessage, 'error', contains('no son correctos')),
      ]),
    );
    bloc.add(_event(UserRole.cliente));
    await expectation;
  });

  test('un error inesperado no deja el estado en loading', () async {
    env.auth.signInError = StateError('algo raro');
    final bloc = env.loginBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(LoginStatus.loading),
        _status(LoginStatus.failure),
      ]),
    );
    bloc.add(_event(UserRole.cliente));
    await expectation;
  });

  test('ignora un segundo envío mientras el primero se procesa', () async {
    env.profiles.stored = profileWith({UserRole.cliente});
    env.auth.gate = Completer<void>();
    final bloc = env.loginBloc();
    addTearDown(bloc.close);

    bloc.add(_event(UserRole.cliente));
    bloc.add(_event(UserRole.cliente));
    await Future<void>.delayed(Duration.zero);
    env.auth.gate!.complete();
    await bloc.stream.firstWhere((s) => s.status == LoginStatus.success);

    expect(env.auth.signInCalls, 1);
  });
}
