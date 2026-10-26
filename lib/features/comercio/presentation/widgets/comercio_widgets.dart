// lib/src/features/comercio/ui/widgets/comercio_widgets.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';

/// Pestañas del comercio:
/// 0 Inicio, 1 Orden, 2 Catálogo, 3 Comunidad, 4 Perfil, 5 Quejas.
const navComercio = [
  ItemNav(Icons.grid_view_outlined, 'Inicio', iconoActivo: Icons.grid_view_rounded),
  ItemNav(Icons.inventory_2_outlined, 'Orden', iconoActivo: Icons.inventory_2),
  ItemNav(Icons.storefront_outlined, 'Catálogo', iconoActivo: Icons.storefront),
  ItemNav(Icons.people_outline, 'Comunidad', iconoActivo: Icons.people),
  ItemNav(Icons.person_outline, 'Perfil', iconoActivo: Icons.person),
  ItemNav(Icons.chat_bubble_outline, 'Quejas', iconoActivo: Icons.chat_bubble),
];

enum EstadoOrdenComercio { pendiente, enProceso, entregado, cancelado }

extension EstadoOrdenComercioUI on EstadoOrdenComercio {
  Widget get etiqueta => switch (this) {
        EstadoOrdenComercio.pendiente => const EtiquetaEstado.pendiente('Pendiente'),
        EstadoOrdenComercio.enProceso => const EtiquetaEstado.info('En Proceso'),
        EstadoOrdenComercio.entregado => const EtiquetaEstado.exito('Entregado'),
        EstadoOrdenComercio.cancelado => const EtiquetaEstado.error('Cancelado'),
      };
}

/// Tarjeta de orden reciente del comercio.
class OrdenComercioCard extends StatelessWidget {
  final String codigo;
  final EstadoOrdenComercio estado;
  final String hace; // "Hace 5 min"
  final String cliente;
  final int productos;
  final String total;
  final VoidCallback? onVerDetalle;

  const OrdenComercioCard({
    super.key,
    required this.codigo,
    required this.estado,
    required this.hace,
    required this.cliente,
    required this.productos,
    required this.total,
    this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      radio: 22,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      onTap: onVerDetalle,
      child: Column(
        children: [
          Row(
            children: [
              Text(codigo,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.texto)),
              const SizedBox(width: 10),
              estado.etiqueta,
              const Spacer(),
              Icon(Icons.schedule, size: 15, color: t.textoGris),
              const SizedBox(width: 4),
              Text(hace, style: TextStyle(fontSize: 13, color: t.textoGris)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: t.texto)),
                    const SizedBox(height: 2),
                    Text('$productos ${productos == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(fontSize: 14, color: t.textoGris)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(total,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: t.primario)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Ver detalle',
                          style: TextStyle(fontSize: 13, color: t.primario)),
                      Icon(Icons.chevron_right, size: 18, color: t.primario),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta "Tip de Crecimiento" con texto resaltado y botón.
class TarjetaTip extends StatelessWidget {
  final String titulo;
  final String textoAntes;
  final String? resaltado;
  final String textoDespues;
  final String? textoBoton;
  final VoidCallback? onBoton;

  const TarjetaTip({
    super.key,
    required this.titulo,
    required this.textoAntes,
    this.resaltado,
    this.textoDespues = '',
    this.textoBoton,
    this.onBoton,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            t.primarioOscuro.withValues(alpha: 0.08), t.fondo),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: t.texto)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: t.texto.withValues(alpha: 0.75)),
              children: [
                TextSpan(text: textoAntes),
                if (resaltado != null)
                  TextSpan(
                      text: resaltado,
                      style: TextStyle(
                          color: t.primario, fontWeight: FontWeight.w700)),
                TextSpan(text: textoDespues),
              ],
            ),
          ),
          if (textoBoton != null) ...[
            const SizedBox(height: 18),
            BotonSuave(texto: textoBoton!, onTap: onBoton),
          ],
        ],
      ),
    );
  }
}

enum EstadoQueja { pendiente, resuelto }

/// Queja o reclamo recibido por el comercio.
class QuejaCard extends StatelessWidget {
  final String titulo;
  final String fecha;
  final String descripcion;
  final EstadoQueja estado;
  final VoidCallback? onTap;

  const QuejaCard({
    super.key,
    required this.titulo,
    required this.fecha,
    required this.descripcion,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final resuelta = estado == EstadoQueja.resuelto;
    return TarjetaSuave(
      radio: 22,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: t.suave, borderRadius: BorderRadius.circular(12)),
            child: Icon(resuelta ? Icons.error_outline : Icons.schedule,
                color: t.primario),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: t.texto)),
                    ),
                    const SizedBox(width: 8),
                    Text(fecha,
                        style: TextStyle(fontSize: 12, color: t.textoGris)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, color: t.textoGris)),
                const SizedBox(height: 10),
                resuelta
                    ? const EtiquetaEstado.exito('Resuelto')
                    : const EtiquetaEstado.pendiente('Pendiente'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18, left: 4),
            child: Icon(Icons.chevron_right, color: t.textoGris),
          ),
        ],
      ),
    );
  }
}
