import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_categorias_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';

/// HU-11: lo que necesita el formulario de un producto (categorías y el
/// comercio, que se muestra como "Tienda / Sucursal").
class GetFormularioProductoUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final GetCategoriasUseCase _categorias;

  GetFormularioProductoUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required GetCategoriasUseCase categorias,
  })  : _comercioAprobado = comercioAprobado,
        _categorias = categorias;

  Future<FormularioProducto> call() async {
    final comercio = await _comercioAprobado();
    return FormularioProducto(
      categorias: await _categorias(),
      comercio: comercio,
    );
  }
}
