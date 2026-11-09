import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// HU-06: un cliente activa el modo Colaborador con la misma cuenta.
///
/// Exige haber aceptado las condiciones de uso, crea el perfil de colaborador
/// (0 puntos, nivel 1, reputación 0) y agrega el rol colaborador sin quitarle
/// el de cliente. Si la cuenta ya es colaborador no hace nada: no se duplica
/// el perfil. Devuelve el perfil ya actualizado.
class ActivarModoColaboradorUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  ActivarModoColaboradorUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
  })  : _auth = auth,
        _profiles = profiles;

  Future<Profile> call({required bool acceptedTerms}) async {
    if (!acceptedTerms) {
      throw const AuthFailure(
        'Debes aceptar las condiciones de uso para activar el modo '
        'Colaborador.',
      );
    }

    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para activar el modo Colaborador.');
    }

    final profile = await _profiles.getProfile(user.id);
    if (profile.hasRole(UserRole.colaborador)) return profile;
    if (!profile.hasRole(UserRole.cliente)) {
      throw const AuthFailure(
        'Solo una cuenta con perfil de Cliente puede activar el modo '
        'Colaborador.',
      );
    }

    await _profiles.activateCollaboratorMode(user.id);
    return _profiles.getProfile(user.id);
  }
}
