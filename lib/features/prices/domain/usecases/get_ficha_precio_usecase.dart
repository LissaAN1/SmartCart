import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';

/// HU-11: precio, promoción e historial de un producto del comercio.
class GetFichaPrecioUseCase {
  /// Cuántos cambios del historial muestra la pantalla.
  static const limiteHistorial = 10;

  final GetComercioAprobadoUseCase _comercioAprobado;
  final PreciosRepository _precios;

  GetFichaPrecioUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required PreciosRepository precios,
  })  : _comercioAprobado = comercioAprobado,
        _precios = precios;

  Future<FichaPrecio> call(String idProducto) async {
    await _comercioAprobado();
    // En orden y no en paralelo: así un error llega tal cual (con su
    // mensaje) y no envuelto en un ParallelWaitError.
    return FichaPrecio(
      precio: await _precios.precio(idProducto),
      promocion: await _precios.promocion(idProducto),
      historial:
          await _precios.historial(idProducto, limite: limiteHistorial),
    );
  }
}
