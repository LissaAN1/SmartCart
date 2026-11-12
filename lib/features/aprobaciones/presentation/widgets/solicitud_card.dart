import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';

/// Ícono de cada tipo de solicitud.
IconData iconoSolicitud(TipoSolicitud tipo) => switch (tipo) {
      TipoSolicitud.comercio => Icons.storefront_outlined,
      TipoSolicitud.repartidor => Icons.two_wheeler,
    };

/// Fecha corta "dd/mm/aaaa" sin depender de un paquete de formato.
String fechaCorta(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}

/// Una fila de la lista de pendientes del administrador (HU-24).
class SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final VoidCallback? onTap;

  const SolicitudCard({super.key, required this.solicitud, this.onTap});

  String get _detalle {
    final comercio = solicitud.comercio;
    if (comercio != null) {
      return '${comercio.ciudad} · ${comercio.servicio.label}';
    }
    return solicitud.correo ?? solicitud.telefono ?? 'Sin datos de contacto';
  }

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final fecha = solicitud.creadoEn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TarjetaSuave(
        radio: 20,
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
              child:
                  Icon(iconoSolicitud(solicitud.tipo), color: t.primarioOscuro),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    solicitud.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: t.texto),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textoGris),
                  ),
                  if (fecha != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Enviada el ${fechaCorta(fecha)}',
                      style: TextStyle(fontSize: 12, color: t.textoGris),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const EtiquetaEstado.pendiente('Pendiente'),
            Icon(Icons.chevron_right, color: t.primarioOscuro),
          ],
        ),
      ),
    );
  }
}
