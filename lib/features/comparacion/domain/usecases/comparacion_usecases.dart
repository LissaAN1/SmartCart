import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/comparacion/domain/comparador_carrito.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/comparacion/domain/repository/comparacion_repository.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/radio_reglas.dart';

/// Lee el carrito del cliente con las ofertas de cada producto. Lo usan la
/// comparación y los precios del carrito.
class GetOfertasCarritoUseCase {
  final GetClienteActivoUseCase _cliente;
  final ComparacionRepository _repositorio;

  GetOfertasCarritoUseCase({
    required GetClienteActivoUseCase cliente,
    required ComparacionRepository repositorio,
  })  : _cliente = cliente,
        _repositorio = repositorio;

  Future<List<LineaComparable>> call() async {
    await _cliente();
    return _repositorio.ofertasDelCarrito();
  }
}

/// Calcula las alternativas del carrito completo según la ubicación del
/// cliente y la distancia máxima opcional (HU-18).
class CompararCarritoUseCase {
  ResultadoComparacion call({
    required List<LineaComparable> lineas,
    Ubicacion? cliente,
    int? distanciaMaxM,
  }) {
    if (lineas.isEmpty) {
      throw const AuthFailure(
          'Tu carrito está vacío. Agrega productos para compararlo.');
    }
    if (distanciaMaxM != null) {
      if (cliente == null) {
        throw const AuthFailure(
            'Configura tu ubicación para filtrar por distancia.');
      }
      if (!RadioReglas.radioValido(distanciaMaxM)) {
        throw const AuthFailure(
            'La distancia máxima debe estar entre 1 y 20 km.');
      }
    }
    return ComparadorCarrito.comparar(
      lineas: lineas,
      cliente: cliente,
      distanciaMaxM: distanciaMaxM,
    );
  }
}
