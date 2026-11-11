import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';

/// Contrato para listar y decidir las solicitudes de aprobación (HU-24).
abstract class SolicitudesRepository {
  /// Una página de solicitudes pendientes del [tipo], de la más antigua a la
  /// más reciente.
  Future<PagedResult<Solicitud>> pendientes(
    TipoSolicitud tipo,
    PageRequest request,
  );

  /// Aprueba o rechaza la [solicitud] y notifica al solicitante, todo junto:
  /// o se hacen las dos cosas o ninguna. [motivo] solo se usa al rechazar.
  Future<void> decidir(
    Solicitud solicitud, {
    required bool aprobar,
    String? motivo,
  });
}
