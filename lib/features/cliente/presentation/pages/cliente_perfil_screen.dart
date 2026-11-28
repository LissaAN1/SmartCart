// lib/src/features/cliente/ui/screens/cliente_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/domain/user_role.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../auth/domain/entities/collaborator_stats.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../puntos/domain/nivel_colaborador.dart';
import '../widgets/cliente_widgets.dart';

class ClientePerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  final Profile profile;

  /// Abre el onboarding del colaborador (opción "Activar modo Colaborador").
  final VoidCallback? onActivarColaborador;

  /// HU-17: cuántos productos hay en el carrito (el número de la pestaña).
  final int itemsCarrito;

  /// HU-17: abre los favoritos del cliente. Sin él avisa "próximamente".
  final VoidCallback? onAbrirFavoritos;

  /// HU-20: abre "Mis órdenes". Sin él avisa "próximamente".
  final VoidCallback? onAbrirOrdenes;

  /// HU-19: abre la ubicación y el radio de búsqueda. Sin él avisa
  /// "próximamente".
  final VoidCallback? onAbrirUbicacion;

  const ClientePerfilScreen({
    super.key,
    this.onTab,
    this.onCerrarSesion,
    required this.profile,
    this.onActivarColaborador,
    this.itemsCarrito = 0,
    this.onAbrirFavoritos,
    this.onAbrirOrdenes,

    this.onAbrirUbicacion,
  });

  @override
  Widget build(BuildContext context) {
    // HU-06: si la cuenta ya activó el modo Colaborador se muestran sus
    // puntos, nivel y reputación y desaparece la opción de activarlo.
    final esColaborador = profile.hasRole(UserRole.colaborador);
    final estadisticasColaborador =
        profile.collaborator ?? CollaboratorStats.initial;
    final rating = profile.rating;
    final desde = profile.memberSince;
    return PantallaRol(
      tema: TemaRol.cliente,
      navItems: navCliente(itemsCarrito: itemsCarrito),
      tabActiva: 3,
      onTab: onTab,
      barraSuperior: const BarraMarca(
        sobretitulo: 'SMARTCART',
        titulo: 'Mi Perfil',
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          CabeceraPerfilCliente(
            nombre: profile.fullName,
            correo: profile.email,
            etiquetas: [
              EtiquetaEstado.marca('Cliente'),
              if (rating != null)
                Calificacion(
                    valor: rating, detalle: '(${profile.ratingCount})'),
              if (desde != null)
                EtiquetaEstado.marca('Desde ${mesYAnio(desde)}'),
            ],
          ),
          const SizedBox(height: 26),

          // ══ MODO COLABORADOR ══
          if (esColaborador) ...[
            const TituloSeccion(titulo: 'MODO COLABORADOR'),
            TarjetaEstadisticas(
              items: [
                Estadistica(Icons.stars_outlined,
                    '${estadisticasColaborador.points}', 'Puntos'),
                Estadistica(
                    Icons.military_tech_outlined,
                    NivelColaborador.desdeNumero(estadisticasColaborador.level)
                        .nombre,
                    'Nivel'),
                Estadistica(Icons.verified_outlined,
                    estadisticasColaborador.reputationLabel, 'Reputación'),
              ],
            ),
          ] else
            GrupoMenu(
              items: [
                ItemMenu(
                  icono: Icons.work_outline,
                  titulo: 'Activar modo Colaborador',
                  subtitulo: 'Reporta precios y gana incentivos',
                  onTap: onActivarColaborador,
                ),
              ],
            ),

          // ══ ACTIVIDAD ══
          const TituloSeccion(titulo: 'ACTIVIDAD Y GESTIÓN'),
          GrupoMenu(
            conTarjeta: false,
            items: [
              ItemMenu(
                  icono: Icons.favorite_border,
                  titulo: 'Mis favoritos',
                  subtitulo: 'Productos y comercios que guardaste',
                  onTap:
                      onAbrirFavoritos ?? () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.history,
                  titulo: 'Historial de compras',
                  subtitulo: 'Tus órdenes y calificaciones',
                  onTap: onAbrirOrdenes ?? () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.chat_bubble_outline,
                  titulo: 'Reportar una queja',
                  subtitulo: 'Soporte técnico e incidencias',
                  onTap: () => mostrarProximamente(context)),
            ],
          ),

          // ══ PREFERENCIAS ══
          const TituloSeccion(titulo: 'PREFERENCIAS'),
          GrupoMenu(
            conTarjeta: false,
            items: [
              ItemMenu(
                  icono: Icons.place_outlined,
                  titulo: 'Mi ubicación',
                  subtitulo: 'Dirección y radio de búsqueda',
                  onTap:
                      onAbrirUbicacion ?? () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.notifications_none,
                  titulo: 'Notificaciones',
                  subtitulo: 'Alertas y promociones',
                  onTap: () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.settings_outlined,
                  titulo: 'Ajustes de cuenta',
                  subtitulo: 'Privacidad y seguridad',
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
          const SizedBox(height: 28),
          const PieVersion(),
        ],
      ),
    );
  }
}
