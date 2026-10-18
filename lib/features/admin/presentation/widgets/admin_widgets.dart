// lib/src/features/admin/ui/widgets/admin_widgets.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';

/// Pestañas del administrador:
/// 0 Panel, 1 Aprobar, 2 Reportes, 3 Quejas, 4 Incentivos, 5 Perfil.
List<ItemNav> navAdmin({int pendientes = 0}) => [
      const ItemNav(Icons.grid_view_outlined, 'Panel',
          iconoActivo: Icons.grid_view_rounded),
      ItemNav(Icons.check_circle_outline, 'Aprobar',
          iconoActivo: Icons.check_circle, badge: pendientes),
      const ItemNav(Icons.report_outlined, 'Reportes', iconoActivo: Icons.report),
      const ItemNav(Icons.feedback_outlined, 'Quejas', iconoActivo: Icons.feedback),
      const ItemNav(Icons.favorite_border, 'Incentivos',
          iconoActivo: Icons.favorite),
      const ItemNav(Icons.person_outline, 'Perfil', iconoActivo: Icons.person),
    ];

/// Tarjeta de acceso rápido: ícono circular + título + subtítulo + chevron.
class AccesoRapidoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final int? contador; // badge opcional con pendientes
  final VoidCallback? onTap;

  const AccesoRapidoCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.contador,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    return TarjetaSuave(
      radio: 22,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: t.suave, shape: BoxShape.circle),
            child: Icon(icono, color: t.primarioOscuro),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: t.texto)),
                const SizedBox(height: 2),
                Text(subtitulo,
                    style: TextStyle(fontSize: 13.5, color: t.primario)),
              ],
            ),
          ),
          if (contador != null && contador! > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColoresEstado.rojo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$contador',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
          ],
          Icon(Icons.chevron_right, color: t.primarioOscuro),
        ],
      ),
    );
  }
}

enum EstadoServicio { operativo, degradado, caido }

class ServicioSistema {
  final String nombre;
  final String detalle; // "48 ms latencia"
  final EstadoServicio estado;
  final IconData icono;
  const ServicioSistema(this.nombre, this.detalle, this.estado,
      {this.icono = Icons.dns_outlined});
}

/// Tarjeta "Estado del sistema" con la lista de servicios.
class TarjetaEstadoSistema extends StatelessWidget {
  final List<ServicioSistema> servicios;
  final VoidCallback? onVerHistorial;

  const TarjetaEstadoSistema({
    super.key,
    required this.servicios,
    this.onVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.of(context);
    final todoOk = servicios.every((s) => s.estado == EstadoServicio.operativo);

    return TarjetaSuave(
      radio: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Estado del sistema',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: t.texto)),
              const Spacer(),
              todoOk
                  ? const EtiquetaEstado.exito('Operativo')
                  : const EtiquetaEstado.pendiente('Con incidencias'),
            ],
          ),
          const SizedBox(height: 14),
          for (final s in servicios) ...[
            _fila(t, s),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onVerHistorial,
              style: OutlinedButton.styleFrom(
                backgroundColor: t.fondo,
                foregroundColor: t.primarioOscuro,
                side: BorderSide(color: t.primario.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Ver historial de conexión'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(TemaRol t, ServicioSistema s) {
    final (color, texto) = switch (s.estado) {
      EstadoServicio.operativo => (ColoresEstado.verde, 'Operativo'),
      EstadoServicio.degradado => (ColoresEstado.ambar, 'Lento'),
      EstadoServicio.caido => (ColoresEstado.rojo, 'Caído'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: t.suave, borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icono, size: 20, color: t.primarioOscuro),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nombre,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: t.texto)),
                Text(s.detalle,
                    style: TextStyle(fontSize: 12.5, color: t.textoGris)),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
