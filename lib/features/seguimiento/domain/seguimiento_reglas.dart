import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';

/// Un paso de la barra de progreso de "Mis órdenes" (PREPARANDO, LISTO,
/// EN CAMINO...).
class PasoSeguimiento {
  final String etiqueta;

  /// Estados en los que este paso ya se alcanzó.
  final Set<EstadoOrden> alcanzadoEn;

  const PasoSeguimiento(this.etiqueta, this.alcanzadoEn);
}

/// HU-23: reglas del seguimiento de una orden. Viven aquí (sin Flutter ni
/// Supabase) para que las pantallas solo las muestren y las pruebas las
/// cubran. La base las vuelve a comprobar en `confirmar_recepcion`.
abstract final class SeguimientoReglas {
  static const mensajeSinOrdenes = 'Aún no tienes órdenes';

  static const _despuesDeListo = {
    EstadoOrden.listaParaRecoger,
    EstadoOrden.enCamino,
    EstadoOrden.recogida,
    EstadoOrden.entregada,
  };
  static const _despuesDePreparar = {
    EstadoOrden.enPreparacion,
    ..._despuesDeListo,
  };

  /// Los pasos de la barra, como en el diseño. Una recogida termina en la
  /// tienda; una entrega sigue con el repartidor (HU-22).
  static List<PasoSeguimiento> pasos(TipoEntrega tipo) => switch (tipo) {
        TipoEntrega.recogida => const [
            PasoSeguimiento('PREPARANDO', _despuesDePreparar),
            PasoSeguimiento('LISTO', _despuesDeListo),
            PasoSeguimiento('RECOGIDA', {EstadoOrden.recogida}),
          ],
        TipoEntrega.entrega => const [
            PasoSeguimiento('PREPARANDO', _despuesDePreparar),
            PasoSeguimiento('LISTO', _despuesDeListo),
            PasoSeguimiento(
                'EN CAMINO', {EstadoOrden.enCamino, EstadoOrden.entregada}),
            PasoSeguimiento('ENTREGADA', {EstadoOrden.entregada}),
          ],
      };

  /// Qué tan avanzada va la orden, de 0 a 1, para la barra de progreso.
  static double progreso(Orden orden) {
    if (orden.estado == EstadoOrden.rechazada) return 0;
    final lista = pasos(orden.tipoEntrega);
    final alcanzados =
        lista.where((p) => p.alcanzadoEn.contains(orden.estado)).length;
    // Recién aceptada ya cuenta como un comienzo.
    final inicio = orden.estado == EstadoOrden.aceptada ? 0.5 : 0.0;
    return ((alcanzados + inicio) / lista.length).clamp(0.0, 1.0);
  }

  /// "En curso": sin cerrar y no rechazada (igual que `ordenes_cliente`).
  static bool enCurso(Orden orden) =>
      orden.cerradaEn == null && orden.estado != EstadoOrden.rechazada;

  /// Escenario 2: el cliente puede confirmar la recogida cuando la orden está
  /// lista en la tienda, o la recepción cuando el repartidor la entregó.
  static bool puedeConfirmar(Orden orden) {
    if (orden.cerradaEn != null) return false;
    return switch (orden.tipoEntrega) {
      TipoEntrega.recogida => orden.estado == EstadoOrden.listaParaRecoger ||
          orden.estado == EstadoOrden.recogida,
      TipoEntrega.entrega => orden.estado == EstadoOrden.entregada,
    };
  }

  /// Texto del botón de confirmar según el tipo de entrega.
  static String textoConfirmar(TipoEntrega tipo) => switch (tipo) {
        TipoEntrega.recogida => 'Confirmar recogida',
        TipoEntrega.entrega => 'Confirmar recepción',
      };

  /// Una orden lista para que el cliente vaya por ella: se destaca arriba de
  /// la lista ("¡Tu orden #105 está lista!").
  static bool listaParaRecoger(Orden orden) =>
      orden.tipoEntrega == TipoEntrega.recogida &&
      orden.estado == EstadoOrden.listaParaRecoger &&
      orden.cerradaEn == null;

  /// Código que el cliente muestra en la tienda. Se deriva del número de la
  /// orden, que el comercio también ve.
  static String codigoRecogida(int numero) => 'SC-$numero';

  /// Descripción de cada estado en la línea de tiempo del detalle.
  static String descripcion(EstadoOrden estado, TipoEntrega tipo) =>
      switch (estado) {
        EstadoOrden.generada =>
          'Tu orden fue confirmada y enviada al comercio.',
        EstadoOrden.aceptada => 'El comercio aceptó tu orden.',
        EstadoOrden.enPreparacion =>
          'El comercio está seleccionando tus productos con cuidado.',
        EstadoOrden.listaParaRecoger => tipo == TipoEntrega.recogida
            ? '¡Todo listo! Ya puedes pasar por tu pedido a la tienda.'
            : 'Tu pedido está listo y espera al repartidor.',
        EstadoOrden.enCamino => 'El repartidor va en camino con tu pedido.',
        EstadoOrden.recogida => 'Recogiste tu pedido en la tienda.',
        EstadoOrden.entregada => 'El repartidor entregó tu pedido.',
        EstadoOrden.rechazada => 'El comercio no pudo atender tu orden.',
      };
}
