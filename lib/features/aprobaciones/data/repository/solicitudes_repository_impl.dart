import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/aprobaciones/data/source/supabase_solicitudes_data_source.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';

/// Cumple SolicitudesRepository delegando en el data source de Supabase.
class SolicitudesRepositoryImpl implements SolicitudesRepository {
  final SupabaseSolicitudesDataSource _dataSource;

  SolicitudesRepositoryImpl({required SupabaseSolicitudesDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<Solicitud>> pendientes(
    TipoSolicitud tipo,
    PageRequest request,
  ) {
    return _dataSource.pendientes(tipo, request);
  }

  @override
  Future<void> decidir(
    Solicitud solicitud, {
    required bool aprobar,
    String? motivo,
  }) {
    return _dataSource.decidir(solicitud, aprobar: aprobar, motivo: motivo);
  }
}
