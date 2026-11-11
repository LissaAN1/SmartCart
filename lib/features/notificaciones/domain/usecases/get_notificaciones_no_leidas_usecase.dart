import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';

/// Lee las notificaciones sin leer de la cuenta con sesión iniciada. Sin
/// sesión devuelve una lista vacía.
class GetNotificacionesNoLeidasUseCase {
  final AuthRepository _auth;
  final NotificacionRepository _notificaciones;

  GetNotificacionesNoLeidasUseCase({
    required AuthRepository auth,
    required NotificacionRepository notificaciones,
  })  : _auth = auth,
        _notificaciones = notificaciones;

  Future<List<Notificacion>> call() async {
    final user = _auth.currentUser();
    if (user == null) return const [];
    return _notificaciones.noLeidas(user.id);
  }
}
