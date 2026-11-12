import 'package:smartcart/features/auth/domain/entities/profile.dart';

/// Contrato para guardar y leer los datos y perfiles de una cuenta.
abstract class ProfileRepository {
  /// Guarda la fila de `usuario` y los perfiles de [Profile.roles].
  Future<void> createProfile(Profile profile);

  /// Crea la fila inicial de `perfil_colaborador` de la cuenta [userId].
  Future<void> createCollaboratorProfile(String userId);

  /// Crea la fila de `perfil_repartidor` de la cuenta [userId] en estado
  /// pendiente y sin disponibilidad (HU-08).
  Future<void> createCourierProfile(String userId);

  /// Activa el modo Colaborador (HU-06) de la cuenta [userId]: crea su
  /// `perfil_colaborador` y le agrega el rol colaborador sin quitarle los
  /// que ya tiene. Se puede repetir sin duplicar nada.
  Future<void> activateCollaboratorMode(String userId);

  /// Activa o desactiva la disponibilidad del repartidor con sesión iniciada.
  /// Solo funciona si ya fue aprobado.
  Future<void> setCourierAvailability(bool available);

  /// Lee los datos y perfiles de la cuenta [id].
  Future<Profile> getProfile(String id);
}
