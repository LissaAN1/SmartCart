import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';

/// Una página de los productos del comercio de la cuenta. Solo ve los suyos.
class GetProductosUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final CatalogoRepository _catalogo;

  GetProductosUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required CatalogoRepository catalogo,
  })  : _comercioAprobado = comercioAprobado,
        _catalogo = catalogo;

  Future<PagedResult<Producto>> call(PageRequest request) async {
    final comercio = await _comercioAprobado();
    return _catalogo.productos(comercio.id, request);
  }
}
