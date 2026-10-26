import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/data/repository/auth_repository_impl.dart';
import 'package:smartcart/features/auth/data/repository/profile_repository_impl.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/validators/auth_validators.dart';

/// Abre la sesión, lee el perfil de la cuenta y comprueba que tenga el
/// perfil (rol) con el que quiere entrar.
///
/// Elegir un perfil en la pantalla no autoriza nada: el permiso sale de
/// `usuario_rol`. Si la cuenta no tiene ese perfil cerramos la sesión que
/// acabamos de abrir para no dejarla activa con un perfil que no le toca.
class SignInUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  // Cada capa crea la siguiente, como en los laboratorios; los parámetros
  // opcionales solo existen para poder probar con repositorios falsos.
  SignInUseCase({AuthRepository? auth, ProfileRepository? profiles})
      : _auth = auth ?? AuthRepositoryImpl(),
        _profiles = profiles ?? ProfileRepositoryImpl();

  Future<Profile> call({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final error = AuthValidators.email(email) ??
        AuthValidators.existingPassword(password);
    if (error != null) throw AuthFailure(error);

    final user = await _auth.signIn(email: email.trim(), password: password);

    final Profile profile;
    try {
      profile = await _profiles.getProfile(user.id);
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }

    if (!profile.hasRole(role)) {
      await _auth.signOut();
      throw AuthFailure(
        'Tu cuenta no tiene el perfil de ${role.label}. '
        'Elige otro perfil o crea una cuenta nueva.',
      );
    }
    return profile;
  }
}
