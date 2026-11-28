import 'package:smartcart/features/estadisticas/data/source/supabase_estadisticas_data_source.dart';
import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';
import 'package:smartcart/features/estadisticas/domain/repository/estadisticas_repository.dart';

/// Cumple EstadisticasRepository delegando en el data source de Supabase.
class EstadisticasRepositoryImpl implements EstadisticasRepository {
  final SupabaseEstadisticasDataSource _dataSource;

  EstadisticasRepositoryImpl({
    required SupabaseEstadisticasDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<EstadisticasPlataforma> obtener() => _dataSource.obtener();
}
