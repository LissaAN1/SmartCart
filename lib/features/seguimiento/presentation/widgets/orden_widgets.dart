import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/seguimiento/domain/seguimiento_reglas.dart';

/// "10:45 AM", como en el diseño.
String horaCorta(DateTime fecha) {
  final h = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
  final m = fecha.minute.toString().padLeft(2, '0');
  return '$h:$m ${fecha.hour < 12 ? 'AM' : 'PM'}';
}

/// "Hoy, 10:45 AM", "Ayer, 4:20 PM" o "15 nov 2026, 9:00 AM".
String fechaOrden(DateTime fecha, DateTime ahora) {
  final dia = DateTime(fecha.year, fecha.month, fecha.day);
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final diferencia = hoy.difference(dia).inDays;
  final cuando = switch (diferencia) {
    0 => 'Hoy',
    1 => 'Ayer',
    _ => fechaCorta(fecha),
  };
  return '$cuando, ${horaCorta(fecha)}';
}

/// "hace 2 min", "hace 3 h", "hace 2 días" (para "Actualizado ...").
String tiempoDesde(DateTime fecha, DateTime ahora) {
  final d = ahora.difference(fecha);
  if (d.inMinutes < 1) return 'hace un momento';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  return d.inDays == 1 ? 'hace 1 día' : 'hace ${d.inDays} días';
}

/// La etiqueta del estado, con el color del diseño: naranja si está lista
/// para recoger, verde si se completó, roja si se rechazó, azul en camino y
/// gris mientras se prepara.
class EtiquetaEstadoOrden extends StatelessWidget {
  final Orden orden;

  const EtiquetaEstadoOrden({super.key, required this.orden});

  @override
  Widget build(BuildContext context) {
    final estado = orden.estado;
    final texto = switch (estado) {
      EstadoOrden.generada ||
      EstadoOrden.aceptada ||
      EstadoOrden.enPreparacion =>
        'EN PROCESO',
      // Como en el diseño.
      EstadoOrden.listaParaRecoger => 'LISTO PARA RECOGER',
      _ => estado.label.toUpperCase(),
    };
    return switch (estado) {
      EstadoOrden.listaParaRecoger => EtiquetaEstado.pendiente(texto),
      EstadoOrden.recogida || EstadoOrden.entregada => EtiquetaEstado.exito(texto),
      EstadoOrden.rechazada => EtiquetaEstado.error(texto),
      EstadoOrden.enCamino => EtiquetaEstado.info(texto),
      _ => EtiquetaEstado(
          texto: texto,
          color: TemaRol.of(context).textoGris,
          fondo: TemaRol.of(context).borde,
        ),
    };
  }
}

/// La barra de progreso con los pasos (PREPARANDO, LISTO, EN CAMINO...).
class PasosOrden extends StatelessWidget {
  final Orden orden;

  const PasosOrden({super.key, required this.orden});

  static IconData _icono(String etiqueta) => switch (etiqueta) {
        'PREPARANDO' => Icons.inventory_2_outlined,
        'LISTO' => Icons.check_circle_outline,
        'EN CAMINO' => Icons.local_shipping_outlined,
        'RECOGIDA' => Icons.storefront_outlined,
        _ => Icons.home_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final pasos = SeguimientoReglas.pasos(orden.tipoEntrega);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: SeguimientoReglas.progreso(orden),
            minHeight: 6,
            backgroundColor: t.borde,
            color: t.primario,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final paso in pasos)
              Expanded(
                child: _Paso(
                  icono: _icono(paso.etiqueta),
                  etiqueta: paso.etiqueta,
                  alcanzado: paso.alcanzadoEn.contains(orden.estado),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool alcanzado;

  const _Paso({
    required this.icono,
    required this.etiqueta,
    required this.alcanzado,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: alcanzado ? t.primario : t.borde,
            shape: BoxShape.circle,
          ),
          child: Icon(icono,
              size: 18, color: alcanzado ? t.superficie : t.textoGris),
        ),
        const SizedBox(height: 6),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: alcanzado ? t.primario : t.textoGris,
          ),
        ),
      ],
    );
  }
}

/// La tarjeta de una orden en "Mis órdenes", como en el diseño: número,
/// fecha, estado, comercio y total, la barra de progreso y la acción que
/// corresponde. [acciones] va debajo (por ejemplo, calificar en el
/// historial).
class TarjetaOrden extends StatelessWidget {
  final Orden orden;
  final DateTime ahora;
  final VoidCallback onAbrir;
  final List<Widget> acciones;

  const TarjetaOrden({
    super.key,
    required this.orden,
    required this.ahora,
    required this.onAbrir,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final enCurso = SeguimientoReglas.enCurso(orden);
    final productos = orden.productos == 1
        ? '1 producto'
        : '${orden.productos} productos';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TarjetaSuave(
        radio: 22,
        onTap: onAbrir,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Número y estado arriba; la fecha en su propia línea, así la
            // etiqueta larga ("LISTO PARA RECOGER") no le quita espacio.
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ORDEN #${orden.numero}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: t.textoGris,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                EtiquetaEstadoOrden(orden: orden),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: t.primario),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fechaOrden(orden.creadoEn, ahora),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.texto,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 26, color: t.borde),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: t.suave, shape: BoxShape.circle),
                  child: Icon(Icons.storefront_outlined, color: t.primario),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orden.comercio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: t.texto,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          // El tipo de entrega ya se ve en la barra de pasos.
                          text: '$productos · Total: ',
                          children: [
                            TextSpan(
                              text: formatoCop(orden.total),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: t.texto,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(fontSize: 12.5, color: t.textoGris),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: t.textoGris),
              ],
            ),
            if (enCurso) ...[
              Divider(height: 26, color: t.borde),
              PasosOrden(orden: orden),
            ],
            if (SeguimientoReglas.listaParaRecoger(orden)) ...[
              const SizedBox(height: 14),
              BotonPrimario(texto: 'Ver código de recogida', onTap: onAbrir),
            ] else if (SeguimientoReglas.puedeConfirmar(orden)) ...[
              const SizedBox(height: 14),
              BotonPrimario(
                texto: SeguimientoReglas.textoConfirmar(orden.tipoEntrega),
                onTap: onAbrir,
              ),
            ],
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...acciones,
            ],
          ],
        ),
      ),
    );
  }
}

/// Aviso destacado arriba de la lista: "¡Tu orden #105 está lista!".
class AvisoOrdenLista extends StatelessWidget {
  final Orden orden;
  final VoidCallback onTap;

  const AvisoOrdenLista({super.key, required this.orden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Material(
      color: ColoresEstado.ambarSuave,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.superficie,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.error_outline, color: ColoresEstado.ambar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Tu orden #${orden.numero} está lista!',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ColoresEstado.ambar,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acércate a ${orden.comercio} para recogerla.',
                      style: TextStyle(fontSize: 12.5, color: t.texto),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: ColoresEstado.ambar),
            ],
          ),
        ),
      ),
    );
  }
}
