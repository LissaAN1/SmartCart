import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';

/// Reglas para confirmar una compra (HU-20).
///
/// La base las vuelve a aplicar en `confirmar_compra()`
/// (docs/sql/sprint3_hu20_hu25.sql) con los mismos textos; aquí están como
/// funciones puras para avisar rápido en la pantalla y probarlas. Si cambias
/// una, cámbiala en los dos lados.
abstract final class ComprasReglas {
  /// Largo mínimo de la dirección de entrega.
  static const direccionMinima = 5;

  static const mensajeCarritoVacio =
      'Tu carrito está vacío. Agrega productos para confirmar la compra.';
  static const mensajeNoDisponibles =
      'Hay productos agotados o sin precio. Quítalos del carrito para continuar.';

  /// Si [plan] y las [elecciones] (por id de comercio) permiten confirmar la
  /// compra, devuelve `null`; si no, el motivo.
  static String? validar(
    PlanCompra plan,
    Map<String, EleccionEntrega> elecciones,
  ) {
    if (plan.estaVacio) return mensajeCarritoVacio;
    if (plan.hayNoDisponibles) return mensajeNoDisponibles;

    for (final grupo in plan.registrados) {
      final eleccion = elecciones[grupo.idComercio];
      if (eleccion == null) {
        return 'Elige recogida o entrega para ${grupo.establecimiento}.';
      }
      if (eleccion.tipo != TipoEntrega.entrega) continue;
      if (!grupo.ofreceEntrega) {
        return '${grupo.establecimiento} no ofrece entrega. Elige recogida.';
      }
      if (!direccionValida(eleccion.direccion)) {
        return 'Escribe la dirección de entrega para ${grupo.establecimiento}.';
      }
    }
    return null;
  }

  static bool direccionValida(String? direccion) =>
      (direccion ?? '').trim().length >= direccionMinima;
}
