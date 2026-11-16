import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';

/// HU-11 · escenario 2: marca un producto como disponible o agotado. Conserva
/// el precio actual, así que el producto debe tener precio primero. Devuelve
/// la ficha ya actualizada.
class CambiarDisponibilidadProductoUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final PreciosRepository _precios;

  CambiarDisponibilidadProductoUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required PreciosRepository precios,
  })  : _comercioAprobado = comercioAprobado,
        _precios = precios;

  Future<FichaPrecio> call(String idProducto, bool disponible) async {
    await _comercioAprobado();
    final actual = await _precios.precio(idProducto);
    if (actual == null) {
      throw const AuthFailure(
        'Registra el precio del producto antes de marcar su disponibilidad.',
      );
    }
    if (actual.disponible != disponible) {
      await _precios.guardarPrecio(
        idProducto,
        PrecioDatos(precio: actual.precio, disponible: disponible),
      );
    }
    return leerFichaPrecio(_precios, idProducto);
  }
}
