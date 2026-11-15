import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';

/// Contrato del catálogo de productos de un comercio.
abstract class CatalogoRepository {
  /// Una página de los productos del comercio [idComercio].
  Future<PagedResult<Producto>> productos(
    String idComercio,
    PageRequest request,
  );

  Future<List<Categoria>> categorias();

  Future<Producto> crear(String idComercio, ProductoDatos datos);

  Future<Producto> editar(String idProducto, ProductoDatos datos);

  Future<void> eliminar(String idProducto);

  /// De [codigos], los que ya tiene algún producto del comercio.
  Future<Set<String>> codigosExistentes(
    String idComercio,
    List<String> codigos,
  );

  /// Guarda varios productos de una vez (carga por CSV).
  Future<void> crearVarios(String idComercio, List<ProductoDatos> productos);
}
