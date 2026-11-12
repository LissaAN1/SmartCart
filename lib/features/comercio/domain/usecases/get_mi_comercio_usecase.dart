import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';

/// Lee el comercio de la cuenta con sesión iniciada. Devuelve `null` si no
/// hay sesión o si todavía no lo registró.
class GetMiComercioUseCase {
  final AuthRepository _auth;
  final ComercioRepository _comercios;

  GetMiComercioUseCase({
    required AuthRepository auth,
    required ComercioRepository comercios,
  })  : _auth = auth,
        _comercios = comercios;

  Future<Comercio?> call() async {
    final user = _auth.currentUser();
    if (user == null) return null;
    return _comercios.getMine(user.id);
  }
}
