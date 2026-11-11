import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/admin/data/source/supabase_aprobacion_data_source.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/admin/domain/repository/aprobacion_repository.dart';

/// Cumple AprobacionRepository delegando en el data source de Supabase.
class AprobacionRepositoryImpl implements AprobacionRepository {
  final SupabaseAprobacionDataSource _dataSource;

  AprobacionRepositoryImpl({required SupabaseAprobacionDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<PagedResult<SolicitudAprobacion>> getPendientes(PageRequest request) {
    return _dataSource.getPendientes(request);
  }

  @override
  Future<void> aprobar(SolicitudAprobacion solicitud) {
    return _dataSource.decidir(solicitud, aprobar: true);
  }

  @override
  Future<void> rechazar(SolicitudAprobacion solicitud, String motivo) {
    return _dataSource.decidir(solicitud, aprobar: false, motivo: motivo);
  }
}
