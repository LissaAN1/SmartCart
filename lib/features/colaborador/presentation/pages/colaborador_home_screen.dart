// lib/src/features/colaborador/ui/screens/colaborador_home_screen.dart
// Home del COLABORADOR. Solo UI con datos de ejemplo.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/colaborador_widgets.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/puntos/domain/nivel_colaborador.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/presentation/widgets/reporte_historial_item.dart';

class ColaboradorHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final String nombre;

  /// HU-14: abre el flujo de reporte de precio. Sin él avisa "próximamente".
  final VoidCallback? onReportarPrecio;

  /// HU-14: los últimos reportes reales del colaborador (los más recientes
  /// primero), con sus estados. Los pendientes también se muestran.
  final List<MiReporte> reportes;
  final bool cargandoReportes;
  final String? errorReportes;
  final VoidCallback? onReintentarReportes;

  /// Abre el historial completo. Sin él avisa "próximamente".
  final VoidCallback? onVerHistorial;

  /// HU-16: puntos y nivel reales (de `perfil_colaborador`) y la pantalla con
  /// su historial. Sin ellos la tarjeta muestra el estado inicial.
  final CollaboratorStats stats;
  final VoidCallback? onVerPuntos;

  /// Cuántos reportes se muestran en el Home; el resto está en el historial.
  static const reportesEnHome = 3;

  const ColaboradorHomeScreen({
    super.key,
    this.onTab,
    required this.nombre,
    this.onReportarPrecio,
    this.reportes = const [],
    this.cargandoReportes = false,
    this.errorReportes,
    this.onReintentarReportes,
    this.onVerHistorial,
    this.stats = CollaboratorStats.initial,
    this.onVerPuntos,
  });

  static const _misiones = [
    (titulo: 'Verifica precios de lácteos', tienda: 'Éxito Calle 80', km: '1.2 km', pts: 150, hechos: 2, total: 5),
    (titulo: 'Fotografía la góndola de café', tienda: 'Carulla Calle 85', km: '2.4 km', pts: 90, hechos: 0, total: 3),
    (titulo: 'Confirma ofertas de aseo', tienda: 'D1 Chapinero', km: '0.8 km', pts: 60, hechos: 1, total: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.colaborador,
      navItems: navColaborador(),
      tabActiva: 0,
      onTab: onTab,
      barraSuperior: EncabezadoSaludo(
        nombre: nombre,
        acciones: [
          BotonCircular(icono: Icons.search, onTap: () => mostrarProximamente(context)),
          BotonCircular(
              icono: Icons.notifications_none, conPunto: true, onTap: () => mostrarProximamente(context)),
        ],
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ══ PUNTOS ══
          // HU-16: puntos y nivel reales; tocar la tarjeta abre el historial.
          GestureDetector(
            onTap: onVerPuntos,
            child: TarjetaPuntos(
              puntos: stats.points,
              nivel:
                  'Nivel ${NivelColaborador.desdeNumero(stats.level).nombre}',
              siguienteNivel: NivelColaborador.desdePuntos(stats.points)
                      .siguiente
                      ?.nombre ??
                  'el nivel máximo',
              progreso:
                  NivelColaborador.desdePuntos(stats.points).progreso(stats.points),
              onCanjear: () => mostrarProximamente(context),
            ),
          ),
          const SizedBox(height: 16),

          // ══ ACCIONES RÁPIDAS ══
          Row(
            children: [
              Expanded(
                child: AccionRapida(
                  icono: Icons.photo_camera_outlined,
                  titulo: 'Reportar precio',
                  subtitulo: 'Foto + precio',
                  onTap: onReportarPrecio ?? () => mostrarProximamente(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccionRapida(
                  icono: Icons.qr_code_scanner,
                  titulo: 'Escanear',
                  subtitulo: 'Código de barras',
                  onTap: onReportarPrecio ?? () => mostrarProximamente(context),
                ),
              ),
            ],
          ),

          // ══ MISIONES ══
          TituloSeccion(
            titulo: 'MISIONES CERCA DE TI',
            accion: 'Ver todas',
            onAccion: () => mostrarProximamente(context),
          ),
          for (final m in _misiones) ...[
            MisionCard(
              titulo: m.titulo,
              tienda: m.tienda,
              distancia: m.km,
              recompensa: m.pts,
              completados: m.hechos,
              total: m.total,
              onTap: () => mostrarProximamente(context),
            ),
            const SizedBox(height: 12),
          ],

          // ══ ÚLTIMOS REPORTES ══
          TituloSeccion(
            titulo: 'MIS ÚLTIMOS REPORTES',
            accion: 'Historial',
            onAccion: onVerHistorial ?? () => mostrarProximamente(context),
            padding: const EdgeInsets.only(top: 14, bottom: 8),
          ),
          if (reportes.isNotEmpty)
            GrupoMenu(
              items: [
                for (final r in reportes.take(reportesEnHome))
                  ReporteHistorialItem(reporte: r, onTap: onVerHistorial),
              ],
            )
          else if (cargandoReportes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorReportes != null) ...[
            ErrorMessage(message: errorReportes!),
            TextButton(
              onPressed: onReintentarReportes,
              child: const Text('Reintentar'),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aún no has enviado reportes. Toca "Reportar precio" para '
                'enviar el primero.',
              ),
            ),
          const SizedBox(height: 20),

          const AvisoDestacado(
            icono: Icons.info_outline,
            estilo: EstiloAviso.suave,
            descripcion: 'Ser colaborador requiere un compromiso con la '
                'veracidad de los datos. Reportes falsos pueden llevar a la '
                'suspensión de la cuenta.',
          ),
        ],
      ),
    );
  }
}