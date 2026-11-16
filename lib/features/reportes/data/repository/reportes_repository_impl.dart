import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/data/source/supabase_reportes_data_source.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Cumple ReportesRepository delegando en el data source de Supabase.
class ReportesRepositoryImpl implements ReportesRepository {
  final SupabaseReportesDataSource _dataSource;

  ReportesRepositoryImpl({required SupabaseReportesDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<EstablecimientoCercano>> establecimientosCercanos(
    Ubicacion ubicacion,
    PageRequest request,
  ) =>
      _dataSource.establecimientosCercanos(ubicacion, request);

  @override
  Future<PagedResult<Producto>> buscarProductos(
    String idComercio,
    ConsultaProductoReporte consulta,
    PageRequest request,
  ) =>
      _dataSource.buscarProductos(idComercio, consulta, request);

  @override
  Future<String> enviarReporte(
    String userId,
    ReporteDatos datos,
    FotoReporte foto,
    Ubicacion ubicacion,
  ) =>
      _dataSource.enviarReporte(userId, datos, foto, ubicacion);

  @override
  Future<PagedResult<MiReporte>> misReportes(PageRequest request) =>
      _dataSource.misReportes(request);

  @override
  Future<void> sugerirEstablecimiento(
    String userId,
    SugerenciaDatos datos,
    Ubicacion ubicacion,
  ) =>
      _dataSource.sugerirEstablecimiento(userId, datos, ubicacion);
}
