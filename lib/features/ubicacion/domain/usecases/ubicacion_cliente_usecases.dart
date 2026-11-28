import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/ubicacion/domain/entities/establecimiento_cercano.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/radio_reglas.dart';
import 'package:smartcart/features/ubicacion/domain/repository/geocodificador.dart';
import 'package:smartcart/features/ubicacion/domain/repository/ubicacion_cliente_repository.dart';

const _radioInvalido = 'El radio debe estar entre 1 y 20 km.';

/// Lee la ubicación y el radio guardados del cliente (HU-19). También la
/// usará la comparación del carrito (HU-18).
class GetMiUbicacionUseCase {
  final GetClienteActivoUseCase _cliente;
  final UbicacionClienteRepository _repositorio;

  GetMiUbicacionUseCase({
    required GetClienteActivoUseCase cliente,
    required UbicacionClienteRepository repositorio,
  })  : _cliente = cliente,
        _repositorio = repositorio;

  Future<PreferenciaUbicacion?> call() async {
    await _cliente();
    return _repositorio.obtener();
  }
}

/// Guarda la ubicación y el radio del cliente en su cuenta.
class GuardarMiUbicacionUseCase {
  final GetClienteActivoUseCase _cliente;
  final UbicacionClienteRepository _repositorio;

  GuardarMiUbicacionUseCase({
    required GetClienteActivoUseCase cliente,
    required UbicacionClienteRepository repositorio,
  })  : _cliente = cliente,
        _repositorio = repositorio;

  Future<void> call(PreferenciaUbicacion preferencia) async {
    if (!RadioReglas.radioValido(preferencia.radioM)) {
      throw const AuthFailure(_radioInvalido);
    }
    final direccion = preferencia.direccion;
    if (direccion != null && direccion.length > RadioReglas.direccionMax) {
      throw const AuthFailure(
        'La dirección puede tener hasta ${RadioReglas.direccionMax} caracteres.',
      );
    }
    await _cliente();
    await _repositorio.guardar(preferencia);
  }
}

/// Escenario 2: sin permiso de ubicación, el cliente escribe su dirección y
/// la convertimos en coordenadas.
class BuscarDireccionUseCase {
  final Geocodificador _geocodificador;

  BuscarDireccionUseCase({required Geocodificador geocodificador})
      : _geocodificador = geocodificador;

  /// Devuelve la dirección limpia junto con sus coordenadas.
  Future<({String direccion, Ubicacion ubicacion})> call(String texto) async {
    final direccion = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (direccion.length < RadioReglas.direccionMin) {
      throw const AuthFailure(
        'Escribe tu dirección completa, por ejemplo: Calle 5 # 38-20, Cali.',
      );
    }
    if (direccion.length > RadioReglas.direccionMax) {
      throw const AuthFailure(
        'La dirección puede tener hasta ${RadioReglas.direccionMax} caracteres.',
      );
    }
    return (
      direccion: direccion,
      ubicacion: await _geocodificador.buscar(direccion),
    );
  }
}

/// Escenarios 1 y 3: los comercios aprobados dentro del radio.
class GetComerciosEnRadioUseCase {
  final GetClienteActivoUseCase _cliente;
  final UbicacionClienteRepository _repositorio;

  GetComerciosEnRadioUseCase({
    required GetClienteActivoUseCase cliente,
    required UbicacionClienteRepository repositorio,
  })  : _cliente = cliente,
        _repositorio = repositorio;

  Future<List<EstablecimientoCercano>> call(
    PreferenciaUbicacion preferencia,
  ) async {
    if (!RadioReglas.radioValido(preferencia.radioM)) {
      throw const AuthFailure(_radioInvalido);
    }
    await _cliente();
    return _repositorio.comerciosEnRadio(
      preferencia.ubicacion,
      preferencia.radioM,
    );
  }
}
