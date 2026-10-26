import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

import '../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  test('devuelve el perfil cuando la cuenta tiene el perfil elegido', () async {
    env.profiles.stored = profileWith({UserRole.cliente, UserRole.colaborador});

    final profile = await env.signIn(
      email: 'ana@correo.com',
      password: 'clave1234',
      role: UserRole.colaborador,
    );

    expect(profile.hasRole(UserRole.colaborador), isTrue);
    expect(env.auth.signOutCalls, 0);
  });

  test('elegir un perfil que la cuenta no tiene cierra la sesión', () async {
    env.profiles.stored = profileWith({UserRole.cliente});

    await expectLater(
      env.signIn(
        email: 'ana@correo.com',
        password: 'clave1234',
        role: UserRole.administrador,
      ),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('no tiene el perfil de Administrador'),
        ),
      ),
    );
    expect(env.auth.signOutCalls, 1);
    expect(env.auth.currentUser(), isNull);
  });

  test('si no existe el perfil de la cuenta cierra la sesión y avisa', () async {
    await expectLater(
      env.signIn(
        email: 'ana@correo.com',
        password: 'clave1234',
        role: UserRole.cliente,
      ),
      throwsA(isA<AuthFailure>()),
    );
    expect(env.auth.signOutCalls, 1);
  });

  test('propaga el error de credenciales sin tocar los perfiles', () async {
    env.auth.signInError = const AuthFailure('El correo o la contraseña no son correctos.');

    await expectLater(
      env.signIn(
        email: 'ana@correo.com',
        password: 'mala',
        role: UserRole.cliente,
      ),
      throwsA(isA<AuthFailure>()),
    );
    expect(env.auth.signOutCalls, 0);
  });

  test('rechaza campos vacíos sin llamar a Supabase', () async {
    await expectLater(
      env.signIn(email: '', password: '', role: UserRole.cliente),
      throwsA(isA<AuthFailure>()),
    );
    expect(env.auth.signInCalls, 0);
  });
}
