import 'package:smartcart/features/confianza/data/source/supabase_reporte_incorrecto_data_source.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';

class ReporteIncorrectoRepositoryImpl implements ReporteIncorrectoRepository {
  final SupabaseReporteIncorrectoDataSource _dataSource;

  ReporteIncorrectoRepositoryImpl({
    required SupabaseReporteIncorrectoDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<ResultadoReporte> reportar(String idProducto, {String? motivo}) =>
      _dataSource.reportar(idProducto, motivo: motivo);
}
