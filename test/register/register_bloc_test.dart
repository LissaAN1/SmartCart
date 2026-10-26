import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/register/ui/bloc/register_event.dart';
import 'package:smartcart/features/register/ui/bloc/register_state.dart';

import '../support/fakes.dart';

Matcher _status(RegisterStatus status) =>
    isA<RegisterState>().having((s) => s.status, 'status', status);

RegisterSubmitted _event(UserRole role) => RegisterSubmitted(
      fullName: 'Ana Gómez',
      email: 'ana@correo.com',
      password: 'clave1234',
      role: role,
    );

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  test('emite loading y luego success con el perfil creado', () async {
    final bloc = env.registerBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(RegisterStatus.loading),
        isA<RegisterState>()
            .having((s) => s.status, 'status', RegisterStatus.success)
            .having((s) => s.profile?.roles, 'roles', {UserRole.comercio}),
      ]),
    );
    bloc.add(_event(UserRole.comercio));
    await expectation;
    expect(env.profiles.created, hasLength(1));
  });

  test('emite failure cuando el registro falla', () async {
    env.auth.signUpError = const AuthFailure('Ya existe una cuenta con este correo.');
    final bloc = env.registerBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(RegisterStatus.loading),
        isA<RegisterState>()
            .having((s) => s.status, 'status', RegisterStatus.failure)
            .having((s) => s.errorMessage, 'error', contains('Ya existe')),
      ]),
    );
    bloc.add(_event(UserRole.cliente));
    await expectation;
  });

  test('un administrador nunca llega a crear cuenta', () async {
    final bloc = env.registerBloc();
    addTearDown(bloc.close);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        _status(RegisterStatus.loading),
        _status(RegisterStatus.failure),
      ]),
    );
    bloc.add(_event(UserRole.administrador));
    await expectation;
    expect(env.auth.signUpCalls, 0);
  });

  test('ignora un segundo envío mientras el primero se procesa', () async {
    env.auth.gate = Completer<void>();
    final bloc = env.registerBloc();
    addTearDown(bloc.close);

    bloc.add(_event(UserRole.cliente));
    bloc.add(_event(UserRole.cliente));
    await Future<void>.delayed(Duration.zero);
    env.auth.gate!.complete();
    await bloc.stream.firstWhere((s) => s.status == RegisterStatus.success);

    expect(env.auth.signUpCalls, 1);
  });
}
