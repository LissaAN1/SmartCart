import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';
import 'package:smartcart/features/admin/domain/repository/aprobacion_repository.dart';

/// Trae una página de la lista de solicitudes pendientes. Que solo el
/// administrador pueda verla lo garantiza la base de datos (RLS / función).
class GetSolicitudesPendientesUseCase {
  final AprobacionRepository _repository;

  GetSolicitudesPendientesUseCase({required AprobacionRepository repository})
      : _repository = repository;

  Future<PagedResult<SolicitudAprobacion>> call(PageRequest request) {
    return _repository.getPendientes(request);
  }
}
