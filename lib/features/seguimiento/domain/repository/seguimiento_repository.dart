import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';

/// Contrato del seguimiento de órdenes del cliente (HU-23).
abstract class SeguimientoRepository {
  /// Una página de las órdenes "En curso" ([enCurso] = true) o del
  /// "Historial", de la más reciente a la más antigua.
  Future<PagedResult<Orden>> ordenes({
    required bool enCurso,
    required PageRequest request,
  });

  /// Cuántas órdenes tiene en curso (el número de la pestaña).
  Future<int> cuantasEnCurso();

  /// El detalle de una orden propia, o `null` si no existe o es de otro.
  Future<DetalleOrden?> detalle(String idOrden);

  /// Escenario 2: confirma la recogida o la recepción y cierra la orden.
  Future<void> confirmarRecepcion(String idOrden);
}

/// Dónde recibe el teléfono las notificaciones push (HU-23).
abstract class DispositivosRepository {
  Future<void> registrar(String token, String plataforma);

  Future<void> quitar(String token);
}
