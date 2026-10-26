import 'package:smartcart/features/auth/domain/entities/profile.dart';

/// Contrato para guardar y leer los datos y perfiles de una cuenta.
abstract class ProfileRepository {
  /// Guarda la fila de `usuario` y los perfiles de [Profile.roles].
  Future<void> createProfile(Profile profile);

  /// Crea la fila inicial de `perfil_colaborador` de la cuenta [userId].
  Future<void> createCollaboratorProfile(String userId);

  /// Lee los datos y perfiles de la cuenta [id].
  Future<Profile> getProfile(String id);
}
