import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/busqueda/data/source/supabase_busqueda_data_source.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/repository/busqueda_repository.dart';

/// Cumple BusquedaRepository delegando en el data source de Supabase.
class BusquedaRepositoryImpl implements BusquedaRepository {
  final SupabaseBusquedaDataSource _dataSource;

  BusquedaRepositoryImpl({required SupabaseBusquedaDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<ResultadoBusqueda>> buscar(
    String texto,
    PageRequest request,
  ) =>
      _dataSource.buscar(texto, request);

  @override
  Future<DetalleProducto?> detalle(String clave) => _dataSource.detalle(clave);
}
