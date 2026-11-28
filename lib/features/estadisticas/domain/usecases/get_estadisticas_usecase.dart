import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';
import 'package:smartcart/features/estadisticas/domain/repository/estadisticas_repository.dart';

/// HU-28: las cifras del panel. Comprueba que quien pregunta sea
/// administrador para dar un mensaje claro; la garantía real está en
/// `estadisticas_panel()`, que rechaza a cualquier otra cuenta.
class GetEstadisticasUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final EstadisticasRepository _estadisticas;

  GetEstadisticasUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
    required EstadisticasRepository estadisticas,
  })  : _auth = auth,
        _profiles = profiles,
        _estadisticas = estadisticas;

  Future<EstadisticasPlataforma> call() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para ver las estadísticas.');
    }
    final profile = await _profiles.getProfile(user.id);
    if (!profile.hasRole(UserRole.administrador)) {
      throw const AuthFailure(
        'Solo el administrador puede ver las estadísticas.',
      );
    }
    return _estadisticas.obtener();
  }
}
