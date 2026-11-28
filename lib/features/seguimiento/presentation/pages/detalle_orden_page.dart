import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';
import 'package:smartcart/features/seguimiento/domain/seguimiento_reglas.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/detalle_orden_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/widgets/orden_widgets.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/presentation/widgets/mapa_establecimientos.dart';

/// HU-23: "Detalle de Orden", como en el diseño: la tienda (con su mapa), el
/// código de recogida y el botón para confirmar, la línea de tiempo "Estado
/// del pedido" y el resumen de productos. Al cerrarse devuelve `true` si el
/// cliente confirmó la orden (la lista debe recargarse).
///
/// Necesita un `DetalleOrdenBloc` arriba en el árbol (lo provee `AppRouter`).
class DetalleOrdenPage extends StatelessWidget {
  /// Reloj de la pantalla; las pruebas lo fijan.
  final DateTime Function() ahora;

  const DetalleOrdenPage({super.key, this.ahora = DateTime.now});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.cliente;
    return BlocConsumer<DetalleOrdenBloc, DetalleOrdenState>(
      listenWhen: (antes, ahora) =>
          ahora.aviso != null && antes.aviso?.id != ahora.aviso?.id,
      listener: (context, state) => mostrarAviso(context, state.aviso!),
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.of(context).pop(state.huboCambios);
          },
          child: PantallaRol(
            tema: t,
            barraSuperior: BarraTituloRol(
              titulo: 'Detalle de Orden',
              mostrarAtras: true,
              onAtras: () => Navigator.of(context).pop(state.huboCambios),
            ),
            cuerpo: _cuerpo(context, state),
          ),
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context, DetalleOrdenState state) {
    final detalle = state.detalle;
    if (state.status == DetalleOrdenStatus.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ErrorMessage(
                message: state.errorMessage ?? 'No pudimos cargar la orden.',
              ),
              TextButton(
                onPressed: () =>
                    context.read<DetalleOrdenBloc>().add(DetalleOrdenStarted()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (detalle == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final orden = detalle.orden;
    final momento = ahora();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '#${orden.numero}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TemaRol.of(context).textoGris,
              ),
            ),
            EtiquetaEstadoOrden(orden: orden),
          ],
        ),
        const SizedBox(height: 14),
        _Tienda(detalle: detalle),
        const SizedBox(height: 18),
        _Confirmacion(detalle: detalle, confirmando: state.confirmando),
        const SizedBox(height: 24),
        _LineaDeTiempo(detalle: detalle, ahora: momento),
        const SizedBox(height: 24),
        _Resumen(detalle: detalle),
      ],
    );
  }
}

/// La tienda: un mapa con su ubicación (si la tiene), nombre y dirección.
class _Tienda extends StatelessWidget {
  final DetalleOrden detalle;

  const _Tienda({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final lat = detalle.comercioLatitud;
    final lon = detalle.comercioLongitud;
    final direccion = [
      if ((detalle.comercioDireccion ?? '').isNotEmpty) detalle.comercioDireccion!,
      if ((detalle.comercioCiudad ?? '').isNotEmpty) detalle.comercioCiudad!,
    ].join(', ');
    return TarjetaSuave(
      radio: 22,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lat != null && lon != null)
            MapaEstablecimientos(
              centro: Ubicacion(latitud: lat, longitud: lon),
              puntos: [
                PuntoMapa(
                  ubicacion: Ubicacion(latitud: lat, longitud: lon),
                  titulo: detalle.orden.comercio,
                ),
              ],
              alto: 150,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, color: t.primario),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detalle.orden.comercio,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: t.texto,
                        ),
                      ),
                      if (direccion.isNotEmpty)
                        Text(
                          direccion,
                          style: TextStyle(fontSize: 13, color: t.textoGris),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta verde: el código de recogida (o el destino de la entrega) y el
/// botón para confirmar (escenario 2). Si ya se confirmó, lo dice.
class _Confirmacion extends StatelessWidget {
  final DetalleOrden detalle;
  final bool confirmando;

  const _Confirmacion({required this.detalle, required this.confirmando});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final orden = detalle.orden;
    final cerrada = orden.cerradaEn;
    final recogida = orden.tipoEntrega == TipoEntrega.recogida;
    final codigo = SeguimientoReglas.codigoRecogida(orden.numero);
    final puede = SeguimientoReglas.puedeConfirmar(orden);

    if (orden.estado == EstadoOrden.rechazada) {
      return _Caja(
        color: ColoresEstado.rojoSuave,
        child: Text(
          SeguimientoReglas.descripcion(orden.estado, orden.tipoEntrega),
          style: const TextStyle(color: ColoresEstado.rojo),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.primario,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            recogida ? 'CÓDIGO DE RECOGIDA' : 'ENTREGA A DOMICILIO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: t.superficie.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          if (recogida)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      codigo,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: t.superficie,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar código',
                  icon: Icon(Icons.copy_rounded, color: t.superficie),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: codigo));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    }
                  },
                ),
              ],
            )
          else
            Text(
              detalle.direccionEntrega ?? 'Tu dirección guardada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: t.superficie,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            cerrada != null
                ? 'Confirmaste ${recogida ? 'la recogida' : 'la recepción'} '
                    'el ${fechaHora(cerrada)}.'
                : recogida
                    ? 'Muestra este código en el comercio cuando vayas por tu '
                        'pedido.'
                    : 'El repartidor llevará tu pedido a esta dirección.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: t.superficie.withValues(alpha: 0.9),
            ),
          ),
          if (cerrada == null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('boton-confirmar'),
                onPressed: puede && !confirmando
                    ? () => context
                        .read<DetalleOrdenBloc>()
                        .add(RecepcionConfirmada())
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: t.superficie,
                  foregroundColor: t.primario,
                  disabledBackgroundColor: t.superficie.withValues(alpha: 0.5),
                  disabledForegroundColor: t.primario.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: confirmando
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: t.primario),
                      )
                    : Text(
                        SeguimientoReglas.textoConfirmar(orden.tipoEntrega),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (!puede) ...[
              const SizedBox(height: 8),
              Text(
                recogida
                    ? 'Podrás confirmarla cuando esté lista para recoger.'
                    : 'Podrás confirmarla cuando el repartidor la entregue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: t.superficie.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Caja extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Caja({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );
}

/// "Estado del pedido": lo que ya pasó, con su hora, y el paso final que
/// falta.
class _LineaDeTiempo extends StatelessWidget {
  final DetalleOrden detalle;
  final DateTime ahora;

  const _LineaDeTiempo({required this.detalle, required this.ahora});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final orden = detalle.orden;
    final pasos = detalle.historial;
    final terminada = orden.estado.completada ||
        orden.estado == EstadoOrden.rechazada;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'ESTADO DEL PEDIDO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: t.texto,
                ),
              ),
            ),
            Icon(Icons.schedule, size: 16, color: t.primario),
            const SizedBox(width: 4),
            Text(
              'Actualizado ${tiempoDesde(detalle.actualizadoEn, ahora)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.primario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final (i, paso) in pasos.indexed)
          _PasoLinea(
            titulo: paso.estado.label,
            descripcion:
                SeguimientoReglas.descripcion(paso.estado, orden.tipoEntrega),
            hora: horaCorta(paso.fecha),
            actual: i == pasos.length - 1 && !terminada,
            hecho: true,
            ultimo: i == pasos.length - 1 && terminada,
          ),
        if (!terminada)
          _PasoLinea(
            titulo: orden.tipoEntrega == TipoEntrega.recogida
                ? 'Recogida'
                : 'Entregada',
            descripcion: orden.tipoEntrega == TipoEntrega.recogida
                ? 'Recogerás tu pedido en la tienda.'
                : 'El repartidor dejará tu pedido en tu dirección.',
            hora: null,
            actual: false,
            hecho: false,
            ultimo: true,
          ),
      ],
    );
  }
}

class _PasoLinea extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final String? hora;
  final bool hecho;
  final bool actual;
  final bool ultimo;

  const _PasoLinea({
    required this.titulo,
    required this.descripcion,
    required this.hora,
    required this.hecho,
    required this.actual,
    required this.ultimo,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final color = hecho ? t.primario : t.textoGris;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hecho && !actual ? t.primario : t.superficie,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: hecho && !actual
                      ? Icon(Icons.check, size: 14, color: t.superficie)
                      : Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: hecho ? t.primario : t.borde,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: actual ? t.primario : t.texto,
                          ),
                        ),
                      ),
                      if (hora != null)
                        Text(
                          hora!,
                          style: TextStyle(fontSize: 12, color: t.textoGris),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: TextStyle(fontSize: 13, color: t.textoGris),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Resumen de productos" con el total pagado.
class _Resumen extends StatelessWidget {
  final DetalleOrden detalle;

  const _Resumen({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final unidades = detalle.unidades;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RESUMEN DE PRODUCTOS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: t.texto,
                ),
              ),
            ),
            Text(
              unidades == 1 ? '1 artículo' : '$unidades artículos',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.textoGris,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TarjetaSuave(
          radio: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final item in detalle.items) ...[
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.suave,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_basket_outlined,
                          size: 20, color: t.primario),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombre,
                            style: TextStyle(fontSize: 14.5, color: t.texto),
                          ),
                          Text(
                            'Cantidad: ${item.cantidad}',
                            style:
                                TextStyle(fontSize: 12.5, color: t.textoGris),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatoCop(item.subtotal),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: t.texto,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: t.borde),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total pagado',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: t.texto,
                      ),
                    ),
                  ),
                  Text(
                    formatoCop(detalle.orden.total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: t.primario,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
