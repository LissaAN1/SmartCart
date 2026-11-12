import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/domain/validators/comercio_validators.dart';

/// HU-07: el dueño registra su establecimiento. Valida los datos y guarda el
/// comercio con estado pendiente hasta que el administrador lo apruebe. Si la
/// cuenta ya tiene un comercio devuelve ese mismo en vez de crear otro.
class RegistrarComercioUseCase {
  final AuthRepository _auth;
  final ComercioRepository _comercios;

  RegistrarComercioUseCase({
    required AuthRepository auth,
    required ComercioRepository comercios,
  })  : _auth = auth,
        _comercios = comercios;

  Future<Comercio> call(ComercioDatos datos) async {
    final error = ComercioValidators.nombre(datos.nombre) ??
        ComercioValidators.telefono(datos.telefono) ??
        ComercioValidators.direccion(datos.direccion) ??
        ComercioValidators.ciudad(datos.ciudad) ??
        ComercioValidators.hora(datos.horaApertura) ??
        ComercioValidators.cierre(datos.horaCierre, datos.horaApertura);
    if (error != null) throw AuthFailure(error);

    final user = _auth.currentUser();
    if (user == null) {
      throw const AuthFailure('Inicia sesión para registrar tu comercio.');
    }

    final existing = await _comercios.getMine(user.id);
    if (existing != null) return existing;

    return _comercios.register(
      user.id,
      ComercioDatos(
        nombre: datos.nombre.trim(),
        telefono: datos.telefono.trim(),
        direccion: datos.direccion.trim(),
        ciudad: datos.ciudad.trim(),
        horaApertura: datos.horaApertura.trim(),
        horaCierre: datos.horaCierre.trim(),
        servicio: datos.servicio,
      ),
    );
  }
}
