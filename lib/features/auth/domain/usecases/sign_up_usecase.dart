import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/data/repository/auth_repository_impl.dart';
import 'package:smartcart/features/auth/data/repository/profile_repository_impl.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/validators/auth_validators.dart';

/// Crea la cuenta y después guarda su perfil con el mismo id.
///
/// Es la única pieza que conoce el orden: el perfil se arma con el id que
/// devuelve Auth. Ya existe una política en Supabase que impide asignarse
/// `administrador`, pero igual lo rechazamos aquí para no llegar a crear una
/// cuenta que luego no se pueda completar.
class SignUpUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  SignUpUseCase({AuthRepository? auth, ProfileRepository? profiles})
      : _auth = auth ?? AuthRepositoryImpl(),
        _profiles = profiles ?? ProfileRepositoryImpl();

  Future<Profile> call({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final error = AuthValidators.fullName(fullName) ??
        AuthValidators.email(email) ??
        AuthValidators.phone(phone) ??
        AuthValidators.newPassword(password);
    if (error != null) throw AuthFailure(error);
    if (!role.canSelfRegister) {
      throw AuthFailure(
        'El perfil de ${role.label} lo asigna el equipo de SmartCart.',
      );
    }

    final cleanPhone = phone?.trim();
    final user = await _auth.signUp(email: email.trim(), password: password);
    final profile = Profile(
      id: user.id,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: (cleanPhone == null || cleanPhone.isEmpty) ? null : cleanPhone,
      roles: {role},
    );

    try {
      await _profiles.createProfile(profile);
      if (role == UserRole.colaborador) {
        await _profiles.createCollaboratorProfile(user.id);
      }
    } catch (_) {
      // La cuenta ya existe pero quedó incompleta; no hay política para
      // borrarla desde la app. Cerramos la sesión y lo explicamos.
      await _auth.signOut();
      throw const AuthFailure(
        'Creamos tu cuenta, pero no pudimos guardar tu perfil. '
        'Intenta iniciar sesión o contacta al equipo de SmartCart.',
      );
    }
    return profile;
  }
}
