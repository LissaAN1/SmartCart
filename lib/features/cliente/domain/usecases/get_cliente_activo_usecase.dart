import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// Devuelve el id de la cuenta con sesión iniciada solo si es un cliente.
/// Todos los casos de uso del carrito, los favoritos y la exploración parten
/// de aquí.
///
/// Da un mensaje claro; la garantía real está en la base, donde las políticas
/// RLS y las funciones exigen `es_cliente()`.
class GetClienteActivoUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  GetClienteActivoUseCase({
    required AuthRepository auth,
    required ProfileRepository profiles,
  })  : _auth = auth,
        _profiles = profiles;

  Future<String> call() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para usar el carrito.');
    }
    final profile = await _profiles.getProfile(user.id);
    if (!profile.hasRole(UserRole.cliente)) {
      throw const AuthFailure(
        'Inicia sesión como cliente para usar el carrito y los favoritos.',
      );
    }
    return user.id;
  }
}
