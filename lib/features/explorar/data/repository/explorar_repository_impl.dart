import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/explorar/data/source/supabase_explorar_data_source.dart';
import 'package:smartcart/features/explorar/domain/repository/explorar_repository.dart';

/// Cumple ExplorarRepository delegando en el data source de Supabase.
class ExplorarRepositoryImpl implements ExplorarRepository {
  final SupabaseExplorarDataSource _dataSource;

  ExplorarRepositoryImpl({required SupabaseExplorarDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<ProductoConComercio>> productos(
    String texto,
    PageRequest request,
  ) =>
      _dataSource.productos(texto, request);

  @override
  Future<PagedResult<ComercioResumen>> comercios(
    String texto,
    PageRequest request,
  ) =>
      _dataSource.comercios(texto, request);
}
