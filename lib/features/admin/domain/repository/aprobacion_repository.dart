import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';

/// Contrato para revisar las solicitudes de comercios y repartidores.
abstract class AprobacionRepository {
  /// Una página de solicitudes pendientes (comercios y repartidores juntos).
  Future<PagedResult<SolicitudAprobacion>> getPendientes(PageRequest request);

  /// Aprueba la solicitud y avisa al solicitante.
  Future<void> aprobar(SolicitudAprobacion solicitud);

  /// Rechaza la solicitud con un [motivo] y avisa al solicitante.
  Future<void> rechazar(SolicitudAprobacion solicitud, String motivo);
}
