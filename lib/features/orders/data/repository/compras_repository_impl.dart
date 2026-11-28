import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/orders/data/source/supabase_compras_data_source.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/domain/repository/compras_repository.dart';

/// Cumple ComprasRepository delegando en el data source de Supabase.
class ComprasRepositoryImpl implements ComprasRepository {
  final SupabaseComprasDataSource _dataSource;

  ComprasRepositoryImpl({required SupabaseComprasDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<LineaPrevia>> previsualizar(List<LineaSolicitud> lineas) =>
      _dataSource.previsualizar(lineas);

  @override
  Future<List<OrdenGenerada>> confirmar(
    List<LineaSolicitud> lineas,
    Map<String, EleccionEntrega> elecciones, {
    List<String>? quitarDelCarrito,
  }) =>
      _dataSource.confirmar(
        lineas,
        elecciones,
        quitarDelCarrito: quitarDelCarrito,
      );

  @override
  Future<PagedResult<Orden>> misOrdenes(PageRequest request) =>
      _dataSource.misOrdenes(request);
}
