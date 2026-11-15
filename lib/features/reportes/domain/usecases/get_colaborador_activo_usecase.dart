import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// Devuelve el id de la cuenta con sesión iniciada solo si tiene el modo
/// Colaborador activo (HU-06). Todos los casos de uso de los reportes parten
/// de aquí.
///
/// Da un mensaje claro; la garantía real está en la base, donde
/// `enviar_reporte_precio` y las políticas RLS exigen `es_colaborador()`.
class GetColaboradorActivoUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  GetColaboradorActivoUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
  })  : _auth = auth,
        _profiles = profiles;

  Future<String> call() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para reportar precios.');
    }
    final profile = await _profiles.getProfile(user.id);
    if (!profile.hasRole(UserRole.colaborador)) {
      throw const AuthFailure('Activa el modo Colaborador para reportar precios.');
    }
    return user.id;
  }
}
