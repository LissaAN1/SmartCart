import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// El repartidor activa o desactiva su disponibilidad. Exige sesión iniciada;
/// que además esté aprobado lo verifica la base de datos.
class CambiarDisponibilidadUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  CambiarDisponibilidadUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
  })  : _auth = auth,
        _profiles = profiles;

  Future<void> call(bool available) async {
    if (_auth.currentUser() == null) {
      throw const AuthFailure('Inicia sesión para cambiar tu disponibilidad.');
    }
    await _profiles.setCourierAvailability(available);
  }
}
