import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';
import 'package:smartcart/features/seguimiento/domain/notificaciones_push.dart';
import 'package:smartcart/features/seguimiento/domain/repository/seguimiento_repository.dart';
import 'package:smartcart/features/seguimiento/domain/seguimiento_reglas.dart';

/// HU-23: una página de las órdenes del cliente, "En curso" o "Historial".
class GetOrdenesClienteUseCase {
  final GetClienteActivoUseCase _cliente;
  final SeguimientoRepository _seguimiento;

  GetOrdenesClienteUseCase({
    required GetClienteActivoUseCase cliente,
    required SeguimientoRepository seguimiento,
  })  : _cliente = cliente,
        _seguimiento = seguimiento;

  Future<PagedResult<Orden>> call({
    required bool enCurso,
    required PageRequest request,
  }) async {
    await _cliente();
    return _seguimiento.ordenes(enCurso: enCurso, request: request);
  }
}

/// HU-23: cuántas órdenes tiene el cliente en curso.
class ContarOrdenesEnCursoUseCase {
  final GetClienteActivoUseCase _cliente;
  final SeguimientoRepository _seguimiento;

  ContarOrdenesEnCursoUseCase({
    required GetClienteActivoUseCase cliente,
    required SeguimientoRepository seguimiento,
  })  : _cliente = cliente,
        _seguimiento = seguimiento;

  Future<int> call() async {
    await _cliente();
    return _seguimiento.cuantasEnCurso();
  }
}

/// HU-23: el detalle de una orden propia.
class GetDetalleOrdenUseCase {
  final GetClienteActivoUseCase _cliente;
  final SeguimientoRepository _seguimiento;

  GetDetalleOrdenUseCase({
    required GetClienteActivoUseCase cliente,
    required SeguimientoRepository seguimiento,
  })  : _cliente = cliente,
        _seguimiento = seguimiento;

  Future<DetalleOrden> call(String idOrden) async {
    await _cliente();
    final detalle = await _seguimiento.detalle(idOrden);
    if (detalle == null) {
      throw const AuthFailure('No encontramos esa orden.');
    }
    return detalle;
  }
}

/// HU-23 · escenario 2: el cliente confirma la recogida (o la recepción de
/// la entrega) y la orden se cierra. Devuelve el detalle ya actualizado, así
/// la pantalla hace una sola llamada.
class ConfirmarRecepcionUseCase {
  final GetClienteActivoUseCase _cliente;
  final SeguimientoRepository _seguimiento;

  ConfirmarRecepcionUseCase({
    required GetClienteActivoUseCase cliente,
    required SeguimientoRepository seguimiento,
  })  : _cliente = cliente,
        _seguimiento = seguimiento;

  Future<DetalleOrden> call(DetalleOrden detalle) async {
    if (!SeguimientoReglas.puedeConfirmar(detalle.orden)) {
      throw const AuthFailure(
        'Todavía no puedes confirmar esta orden. Te avisaremos cuando esté '
        'lista.',
      );
    }
    await _cliente();
    await _seguimiento.confirmarRecepcion(detalle.orden.id);
    final actualizado = await _seguimiento.detalle(detalle.orden.id);
    if (actualizado == null) {
      throw const AuthFailure('No encontramos esa orden.');
    }
    return actualizado;
  }
}

/// HU-23: activa las notificaciones push del teléfono y guarda su token en
/// la cuenta. Devuelve si quedaron activas. Sin permiso o sin Firebase
/// configurado no falla: la app sigue con los avisos dentro de la app.
class ActivarNotificacionesPushUseCase {
  final AuthRepository _auth;
  final NotificacionesPush _push;
  final DispositivosRepository _dispositivos;

  ActivarNotificacionesPushUseCase({
    required AuthRepository auth,
    required NotificacionesPush push,
    required DispositivosRepository dispositivos,
  })  : _auth = auth,
        _push = push,
        _dispositivos = dispositivos;

  Future<bool> call() async {
    if (_auth.currentUser() == null) return false;
    final token = await _push.activar();
    if (token == null) return false;
    await _dispositivos.registrar(token, _push.plataforma);
    return true;
  }

  /// Firebase renovó el token: se guarda el nuevo.
  Future<void> renovar(String token) async {
    if (_auth.currentUser() == null) return;
    await _dispositivos.registrar(token, _push.plataforma);
  }
}
