// Perfil del COLABORADOR con los datos reales de su cuenta y de
// `perfil_colaborador`: puntos, nivel (Nuevo, Frecuente o Experto) y
// reputación (HU-16). Sin tabla de ganancias todavía, no se muestran.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../auth/domain/entities/collaborator_stats.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../puntos/domain/nivel_colaborador.dart';
import '../widgets/colaborador_widgets.dart';

class ColaboradorPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  final Profile profile;

  /// HU-16: puntos, nivel, reputación e historial de puntos.
  final VoidCallback? onVerPuntos;

  /// HU-14: historial completo de reportes (con su estado y motivo, HU-15).
  final VoidCallback? onVerHistorial;

  /// HU-15: reportes de otras personas que esperan confirmación.
  final VoidCallback? onPorConfirmar;

  const ColaboradorPerfilScreen({
    super.key,
    this.onTab,
    this.onCerrarSesion,
    required this.profile,
    this.onVerPuntos,
    this.onVerHistorial,
    this.onPorConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.colaborador;
    final stats = profile.collaborator ?? CollaboratorStats.initial;
    final desde = profile.memberSince;
    return PantallaRol(
      tema: t,
      navItems: navColaborador(),
      tabActiva: 3,
      onTab: onTab,
      // El perfil es una pestaña del shell, no una ruta apilada: "atrás"
      // vuelve a la pestaña Home en lugar de intentar cerrar la pantalla.
      barraSuperior: BarraTituloRol(
        titulo: 'Mi Perfil',
        mostrarAtras: true,
        onAtras: () => onTab?.call(0),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: profile.fullName,
            correo: profile.email,
            insignia: Icons.verified_outlined,
            etiquetas: [
              EtiquetaEstado.marca('Colaborador'),
              if (desde != null) EtiquetaEstado.marca('Desde ${mesYAnio(desde)}'),
            ],
          ),
          const SizedBox(height: 22),

          // ══ ESTADÍSTICAS ══
          TarjetaEstadisticas(
            items: [
              Estadistica(Icons.stars_outlined, '${stats.points}', 'Puntos'),
              Estadistica(Icons.military_tech_outlined,
                  NivelColaborador.desdeNumero(stats.level).nombre, 'Nivel'),
              Estadistica(Icons.verified_outlined, stats.reputationLabel,
                  'Reputación'),
            ],
          ),

          // ══ ACTIVIDAD ══
          const TituloSeccion(titulo: 'ACTIVIDAD'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.stars_outlined,
                  titulo: 'Mis puntos',
                  subtitulo: 'Nivel, reputación e historial de puntos',
                  onTap: onVerPuntos ?? () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.chat_bubble_outline,
                  titulo: 'Historial de reportes',
                  subtitulo: 'Ver el estado y el motivo de cada reporte',
                  onTap: onVerHistorial ?? () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Reportes por confirmar',
                  subtitulo: 'Ayuda a validar precios dudosos',
                  onTap: onPorConfirmar ?? () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.share_outlined,
                  titulo: 'Referir a un amigo',
                  onTap: () => mostrarProximamente(context)),
            ],
          ),

          // ══ CONFIGURACIÓN ══
          const TituloSeccion(titulo: 'CONFIGURACIÓN'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.settings_outlined,
                  titulo: 'Ajustes de cuenta',
                  onTap: () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.help_outline,
                  titulo: 'Ayuda y Soporte',
                  onTap: () => mostrarProximamente(context)),
              ItemMenu(
                icono: Icons.logout,
                titulo: 'Cerrar sesión',
                peligro: true,
                onTap: () => confirmarCierreSesion(context, onCerrarSesion),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const PieVersion(),
        ],
      ),
    );
  }
}
