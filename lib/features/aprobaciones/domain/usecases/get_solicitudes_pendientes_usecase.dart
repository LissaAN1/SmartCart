import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';

/// HU-24: trae una página de solicitudes pendientes del [TipoSolicitud]
/// indicado. Quién puede leerlas lo decide la política RLS: a una cuenta que
/// no es administrador la base no le devuelve solicitudes ajenas.
class GetSolicitudesPendientesUseCase {
  final SolicitudesRepository _solicitudes;

  GetSolicitudesPendientesUseCase({required SolicitudesRepository solicitudes})
      : _solicitudes = solicitudes;

  Future<PagedResult<Solicitud>> call(
    TipoSolicitud tipo,
    PageRequest request,
  ) {
    return _solicitudes.pendientes(tipo, request);
  }
}
