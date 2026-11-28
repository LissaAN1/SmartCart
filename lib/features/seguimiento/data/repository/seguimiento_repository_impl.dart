import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/seguimiento/data/source/supabase_seguimiento_data_source.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';
import 'package:smartcart/features/seguimiento/domain/repository/seguimiento_repository.dart';

/// Cumple SeguimientoRepository delegando en el data source de Supabase.
class SeguimientoRepositoryImpl implements SeguimientoRepository {
  final SupabaseSeguimientoDataSource _dataSource;

  SeguimientoRepositoryImpl({required SupabaseSeguimientoDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<Orden>> ordenes({
    required bool enCurso,
    required PageRequest request,
  }) =>
      _dataSource.ordenes(enCurso: enCurso, request: request);

  @override
  Future<int> cuantasEnCurso() => _dataSource.cuantasEnCurso();

  @override
  Future<DetalleOrden?> detalle(String idOrden) => _dataSource.detalle(idOrden);

  @override
  Future<void> confirmarRecepcion(String idOrden) =>
      _dataSource.confirmarRecepcion(idOrden);
}

/// Cumple DispositivosRepository con el mismo data source.
class DispositivosRepositoryImpl implements DispositivosRepository {
  final SupabaseSeguimientoDataSource _dataSource;

  DispositivosRepositoryImpl({required SupabaseSeguimientoDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<void> registrar(String token, String plataforma) =>
      _dataSource.registrarDispositivo(token, plataforma);

  @override
  Future<void> quitar(String token) => _dataSource.quitarDispositivo(token);
}
