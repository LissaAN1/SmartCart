import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';

/// Cuántos cambios del historial se leen: alcanzan para la gráfica de los
/// últimos meses.
const limiteHistorialPrecios = 60;

/// Lee precio, promoción e historial de un producto. La usan la consulta y
/// los casos de uso que escriben, para devolver la ficha ya actualizada (con
/// la fecha y el historial que guardó la base) en una sola llamada del Bloc.
Future<FichaPrecio> leerFichaPrecio(
  PreciosRepository precios,
  String idProducto,
) async {
  // En orden y no en paralelo: así un error llega tal cual (con su mensaje)
  // y no envuelto en un ParallelWaitError.
  return FichaPrecio(
    precio: await precios.precio(idProducto),
    promocion: await precios.promocion(idProducto),
    historial:
        await precios.historial(idProducto, limite: limiteHistorialPrecios),
  );
}

/// HU-11: precio, promoción e historial de un producto del comercio.
class GetFichaPrecioUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final PreciosRepository _precios;

  GetFichaPrecioUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required PreciosRepository precios,
  })  : _comercioAprobado = comercioAprobado,
        _precios = precios;

  Future<FichaPrecio> call(String idProducto) async {
    await _comercioAprobado();
    return leerFichaPrecio(_precios, idProducto);
  }
}
