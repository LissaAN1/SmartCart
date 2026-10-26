import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

import '../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  Future<void> register(UserRole role, {String? phone = '3001234567'}) {
    return env.signUp(
      fullName: '  Ana Gómez ',
      email: 'ana@correo.com',
      phone: phone,
      password: 'clave1234',
      role: role,
    );
  }

  test('crea la cuenta y después el perfil con el mismo id', () async {
    final profile = await env.signUp(
      fullName: '  Ana Gómez ',
      email: ' ana@correo.com ',
      phone: '3001234567',
      password: 'clave1234',
      role: UserRole.cliente,
    );

    expect(profile.id, 'u1');
    expect(profile.fullName, 'Ana Gómez');
    expect(profile.email, 'ana@correo.com');
    expect(profile.roles, {UserRole.cliente});
    expect(env.profiles.created.single.id, env.auth.current!.id);
    expect(env.profiles.collaboratorIds, isEmpty);
  });

  test('el colaborador también recibe su perfil_colaborador inicial', () async {
    await register(UserRole.colaborador);
    expect(env.profiles.collaboratorIds, ['u1']);
  });

  test('el teléfono vacío se guarda como nulo', () async {
    await register(UserRole.cliente, phone: '  ');
    expect(env.profiles.created.single.phone, isNull);
  });

  test('no permite registrarse como administrador y no crea la cuenta', () async {
    await expectLater(
      register(UserRole.administrador),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('lo asigna el equipo de SmartCart'),
        ),
      ),
    );
    expect(env.auth.signUpCalls, 0);
  });

  test('valida los datos antes de llamar a Supabase', () async {
    await expectLater(
      env.signUp(
        fullName: 'Ana',
        email: 'no-es-correo',
        password: 'clave1234',
        role: UserRole.cliente,
      ),
      throwsA(isA<AuthFailure>()),
    );
    expect(env.auth.signUpCalls, 0);
  });

  test('si el correo ya existe no se intenta guardar el perfil', () async {
    env.auth.signUpError = const AuthFailure('Ya existe una cuenta con este correo.');

    await expectLater(register(UserRole.cliente), throwsA(isA<AuthFailure>()));
    expect(env.profiles.created, isEmpty);
  });

  test('si falla el perfil cierra la sesión y explica qué pasó', () async {
    env.profiles.createError = const AuthFailure('No tienes permiso para realizar esta acción.');

    await expectLater(
      register(UserRole.cliente),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Creamos tu cuenta'),
        ),
      ),
    );
    expect(env.auth.signOutCalls, 1);
  });
}
