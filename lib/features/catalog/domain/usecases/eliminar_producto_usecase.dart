import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';

/// HU-10: el comercio aprobado elimina un producto de su catálogo. Es un
/// borrado definitivo; la pantalla pide confirmación antes de llamarlo.
class EliminarProductoUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final CatalogoRepository _catalogo;

  EliminarProductoUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required CatalogoRepository catalogo,
  })  : _comercioAprobado = comercioAprobado,
        _catalogo = catalogo;

  Future<void> call(String idProducto) async {
    await _comercioAprobado();
    await _catalogo.eliminar(idProducto);
  }
}
