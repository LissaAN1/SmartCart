import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/data/source/supabase_catalogo_data_source.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';

/// Cumple CatalogoRepository delegando en el data source de Supabase.
class CatalogoRepositoryImpl implements CatalogoRepository {
  final SupabaseCatalogoDataSource _dataSource;

  CatalogoRepositoryImpl({required SupabaseCatalogoDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<Producto>> productos(
    String idComercio,
    PageRequest request, {
    FiltroCatalogo filtro = const FiltroCatalogo(),
  }) =>
      _dataSource.productos(idComercio, request, filtro: filtro);

  @override
  Future<ResumenCatalogo> resumen(String idComercio) =>
      _dataSource.resumen(idComercio);

  @override
  Future<Producto> subirFoto(
    String idComercio,
    Producto producto,
    ImagenProducto foto,
  ) =>
      _dataSource.subirFoto(idComercio, producto, foto);

  @override
  Future<List<Categoria>> categorias() => _dataSource.categorias();

  @override
  Future<Producto> crear(String idComercio, ProductoDatos datos) =>
      _dataSource.crear(idComercio, datos);

  @override
  Future<Producto> editar(String idProducto, ProductoDatos datos) =>
      _dataSource.editar(idProducto, datos);

  @override
  Future<void> eliminar(String idProducto) => _dataSource.eliminar(idProducto);

  @override
  Future<Set<String>> codigosExistentes(
    String idComercio,
    List<String> codigos,
  ) =>
      _dataSource.codigosExistentes(idComercio, codigos);

  @override
  Future<void> crearVarios(String idComercio, List<ProductoDatos> productos) =>
      _dataSource.crearVarios(idComercio, productos);
}
