// lib/src/features/admin/ui/screens/admin_home_screen.dart
// Home del ADMINISTRADOR ("Panel").
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/admin_widgets.dart';
import 'package:smartcart/features/estadisticas/presentation/bloc/estadisticas_bloc.dart';
import 'package:smartcart/features/estadisticas/presentation/widgets/panel_estadisticas.dart';

class AdminHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final String nombre;

  /// HU-24: abre la lista de comercios y repartidores pendientes.
  final VoidCallback? onAbrirAprobaciones;

  /// HU-28: las cifras del panel; las consulta el `RolShell`.
  final EstadisticasState? estadisticas;
  final VoidCallback? onReintentar;

  const AdminHomeScreen({
    super.key,
    this.onTab,
    required this.nombre,
    this.onAbrirAprobaciones,
    this.estadisticas,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    final datos = estadisticas?.datos;
    final pendientes = datos?.solicitudesPendientes ?? 0;
    return PantallaRol(
      tema: t,
      navItems: navAdmin(pendientes: pendientes),
      tabActiva: 0,
      onTab: onTab,
      barraSuperior: BarraMarca(
        iconoLogo: Icons.shopping_basket_outlined,
        trailing: AvatarPerfil(radio: 22, nombre: nombre, enLinea: true),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
        children: [
          // ══ SALUDO ══
          Text('Panel de control',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: t.texto)),
          const SizedBox(height: 4),
          Text('Resumen de la plataforma hoy',
              style: TextStyle(fontSize: 14, color: t.textoGris)),
          const SizedBox(height: 18),

          // ══ CIFRAS (HU-28) ══
          PanelEstadisticas(
            estado: estadisticas,
            onReintentar: onReintentar,
          ),
          const SizedBox(height: 18),

          // ══ ACCESOS RÁPIDOS ══
          const TituloSeccion(
            titulo: 'Accesos Rápidos',
            estilo: EstiloTitulo.grande,
          ),
          AccesoRapidoCard(
            icono: Icons.check_circle_outline,
            titulo: 'Aprobaciones',
            subtitulo: 'Comercios y repartidores pendientes',
            contador: pendientes,
            onTap: onAbrirAprobaciones,
          ),
          const SizedBox(height: 12),
          AccesoRapidoCard(
            icono: Icons.shield_outlined,
            titulo: 'Moderación',
            subtitulo: 'Revisión de productos reportados',
            onTap: () => mostrarProximamente(context),
          ),
          const SizedBox(height: 12),
          AccesoRapidoCard(
            icono: Icons.error_outline,
            titulo: 'Quejas',
            subtitulo: 'Gestión de reclamos activos',
            onTap: () => mostrarProximamente(context),
          ),
          const SizedBox(height: 12),
          AccesoRapidoCard(
            icono: Icons.card_giftcard,
            titulo: 'Incentivos',
            subtitulo: 'Configuración de puntos y niveles',
            onTap: () => mostrarProximamente(context),
          ),
          const SizedBox(height: 24),

          // ══ ACCIÓN REQUERIDA ══
          // Con las cifras cargadas, el aviso solo sale si hay solicitudes.
          if (datos == null || pendientes > 0)
            AvisoDestacado(
              icono: Icons.assignment_late_outlined,
              titulo: 'Acción Requerida',
              descripcion: 'Revisa las solicitudes de comercios y repartidores '
                  'pendientes: no pueden operar hasta que las apruebes.',
              onTap: onAbrirAprobaciones,
            ),
        ],
      ),
    );
  }
}
