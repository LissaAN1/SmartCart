import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/data/source/supabase_favoritos_data_source.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:smartcart/features/favoritos/domain/repository/favoritos_repository.dart';

/// Cumple FavoritosRepository delegando en el data source de Supabase.
class FavoritosRepositoryImpl implements FavoritosRepository {
  final SupabaseFavoritosDataSource _dataSource;

  FavoritosRepositoryImpl({required SupabaseFavoritosDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<FavoritosIds> ids() => _dataSource.ids();

  @override
  Future<PagedResult<ProductoConComercio>> productos(PageRequest request) =>
      _dataSource.productos(request);

  @override
  Future<PagedResult<ComercioResumen>> comercios(PageRequest request) =>
      _dataSource.comercios(request);

  @override
  Future<void> cambiar(
    TipoFavorito tipo,
    String id, {
    required bool favorito,
  }) =>
      _dataSource.cambiar(tipo, id, favorito: favorito);
}
