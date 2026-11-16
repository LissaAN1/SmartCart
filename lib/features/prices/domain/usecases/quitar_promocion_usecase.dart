import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';

/// HU-11: elimina la promoción de un producto; vuelve a regir el precio
/// normal.
class QuitarPromocionUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final PreciosRepository _precios;

  QuitarPromocionUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required PreciosRepository precios,
  })  : _comercioAprobado = comercioAprobado,
        _precios = precios;

  Future<void> call(String idProducto) async {
    await _comercioAprobado();
    await _precios.quitarPromocion(idProducto);
  }
}
