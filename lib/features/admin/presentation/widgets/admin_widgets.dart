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
