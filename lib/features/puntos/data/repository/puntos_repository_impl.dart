import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/puntos/data/source/supabase_puntos_data_source.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/repository/puntos_repository.dart';

/// Cumple PuntosRepository delegando en el data source de Supabase.
class PuntosRepositoryImpl implements PuntosRepository {
  final SupabasePuntosDataSource _dataSource;

  PuntosRepositoryImpl({required SupabasePuntosDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<ResumenPuntos> resumen() => _dataSource.resumen();

  @override
  Future<PagedResult<MovimientoPuntos>> movimientos(PageRequest request) =>
      _dataSource.movimientos(request);
}
