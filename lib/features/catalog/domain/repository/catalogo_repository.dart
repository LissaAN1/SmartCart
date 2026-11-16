import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';

/// Contrato del catálogo de productos de un comercio.
abstract class CatalogoRepository {
  /// Una página de los productos del comercio [idComercio]. Con [filtro]
  /// (HU-11) busca por nombre o marca y por categoría.
  Future<PagedResult<Producto>> productos(
    String idComercio,
    PageRequest request, {
    FiltroCatalogo filtro = const FiltroCatalogo(),
  });

  /// HU-11: total de productos, valor del stock y productos con stock bajo.
  Future<ResumenCatalogo> resumen(String idComercio);

  /// HU-11: sube la foto a la carpeta del comercio y la guarda en el
  /// producto. Devuelve el producto con su nueva `fotoUrl`.
  Future<Producto> subirFoto(
    String idComercio,
    Producto producto,
    ImagenProducto foto,
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
