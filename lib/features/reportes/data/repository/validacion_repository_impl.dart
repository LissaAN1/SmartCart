import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/reportes/data/source/supabase_validacion_data_source.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/repository/validacion_repository.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Cumple ValidacionRepository delegando en el data source de Supabase.
class ValidacionRepositoryImpl implements ValidacionRepository {
  final SupabaseValidacionDataSource _dataSource;

  ValidacionRepositoryImpl({required SupabaseValidacionDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<ReportePorConfirmar>> porConfirmar(PageRequest request) =>
      _dataSource.porConfirmar(request);

  @override
  Future<PagedResult<ReportePorConfirmar>> deMiComercio(PageRequest request) =>
      _dataSource.deMiComercio(request);

  @override
  Future<void> confirmarComoColaborador(
    String idReporte,
    Ubicacion ubicacion,
  ) =>
      _dataSource.confirmarComoColaborador(idReporte, ubicacion);

  @override
  Future<void> confirmarComoComercio(String idReporte) =>
      _dataSource.confirmarComoComercio(idReporte);

  @override
  Future<void> corregirComoComercio(String idReporte, int precio) =>
      _dataSource.corregirComoComercio(idReporte, precio);
}
