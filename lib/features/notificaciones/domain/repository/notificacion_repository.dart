import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';

/// Contrato para leer las notificaciones de una cuenta.
abstract class NotificacionRepository {
  /// Las notificaciones sin leer de [userId], de la más antigua a la más
  /// reciente.
  Future<List<Notificacion>> noLeidas(String userId);

  /// Marca como leídas las notificaciones [ids].
  Future<void> marcarLeidas(List<String> ids);
}
