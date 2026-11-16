import 'package:smartcart/features/prices/data/source/supabase_precios_data_source.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';

/// Cumple PreciosRepository delegando en el data source de Supabase.
class PreciosRepositoryImpl implements PreciosRepository {
  final SupabasePreciosDataSource _dataSource;

  PreciosRepositoryImpl({required SupabasePreciosDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PrecioProducto?> precio(String idProducto) =>
      _dataSource.precio(idProducto);

  @override
  Future<Promocion?> promocion(String idProducto) =>
      _dataSource.promocion(idProducto);

  @override
  Future<List<RegistroPrecio>> historial(String idProducto,
          {int limite = 10}) =>
      _dataSource.historial(idProducto, limite);

  @override
  Future<PrecioProducto> guardarPrecio(String idProducto, PrecioDatos datos) =>
      _dataSource.guardarPrecio(idProducto, datos);

  @override
  Future<Promocion> guardarPromocion(
          String idProducto, PromocionDatos datos) =>
      _dataSource.guardarPromocion(idProducto, datos);

  @override
  Future<void> quitarPromocion(String idProducto) =>
      _dataSource.quitarPromocion(idProducto);
}
