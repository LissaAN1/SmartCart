import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';

/// Marca como leídas las notificaciones que la persona ya vio, para no
/// volver a mostrárselas.
class MarcarNotificacionesLeidasUseCase {
  final NotificacionRepository _notificaciones;

  MarcarNotificacionesLeidasUseCase({
    required NotificacionRepository notificaciones,
  }) : _notificaciones = notificaciones;

  Future<void> call(List<Notificacion> vistas) async {
    if (vistas.isEmpty) return;
    await _notificaciones.marcarLeidas([for (final n in vistas) n.id]);
  }
}
