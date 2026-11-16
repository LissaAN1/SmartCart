import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';

/// HU-14: guarda la ubicación actual del dueño como la del comercio, para
/// que los colaboradores puedan reportar precios ahí. Se usa desde el Home,
/// porque los comercios registrados antes de esta historia no la tienen.
///
/// Devuelve el comercio ya actualizado.
class FijarUbicacionComercioUseCase {
  final AuthRepository _auth;
  final ComercioRepository _comercios;
  final ObtenerUbicacionUseCase _ubicacion;

  FijarUbicacionComercioUseCase({
    required AuthRepository auth,
    required ComercioRepository comercios,
    required ObtenerUbicacionUseCase ubicacion,
  })  : _auth = auth,
        _comercios = comercios,
        _ubicacion = ubicacion;

  Future<Comercio> call() async {
    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para guardar la ubicación.');
    }
    // Primero comprobamos que exista el comercio: así no pedimos el GPS para
    // nada si la cuenta todavía no lo registró.
    if (await _comercios.getMine(user.id) == null) {
      throw const AuthFailure('Primero registra tu comercio.');
    }
    await _comercios.fijarUbicacion(await _ubicacion());
    final actualizado = await _comercios.getMine(user.id);
    if (actualizado == null) {
      throw const AuthFailure('No pudimos leer tu comercio. Inténtalo de nuevo.');
    }
    return actualizado;
  }
}
