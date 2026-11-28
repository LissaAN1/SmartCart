// Perfil del COMERCIO con los datos reales de su registro (tabla `comercio`)
// y de la cuenta del dueño. Sin tablas de ventas, reseñas ni quejas todavía,
// no se muestran esas cifras.
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../domain/entities/comercio.dart';
import '../widgets/comercio_widgets.dart';

class ComercioPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  final Profile profile;
  final Comercio comercio;

  /// HU-15: reportes de la comunidad que el comercio confirma o corrige.
  final VoidCallback? onReportesComunidad;
  const ComercioPerfilScreen({
    super.key,
    this.onTab,
    this.onCerrarSesion,
    required this.profile,
    required this.comercio,
    this.onReportesComunidad,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.comercio;
    return PantallaRol(
      tema: t,
      navItems: navComercio,
      tabActiva: 4,
      onTab: onTab,
      barraSuperior: const BarraTituloRol(titulo: 'Mi Perfil'),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: comercio.nombre,
            insignia: Icons.storefront_outlined,
            ubicacion: '${comercio.ciudad} - ${comercio.direccion}',
            etiquetas: [
              EtiquetaEstado.marca(comercio.servicio.label),
              const EtiquetaEstado.exito('Aprobado'),
              // HU-25: el promedio de las calificaciones de los clientes.
              if (profile.rating != null && profile.ratingCount > 0)
                Calificacion(
                    valor: profile.rating!,
                    detalle: '(${profile.ratingCount})')
              else
                EtiquetaEstado.marca('Sin calificaciones'),
            ],
          ),
          const SizedBox(height: 20),

          // ══ DATOS DEL ESTABLECIMIENTO ══
          const TituloSeccion(titulo: 'MI ESTABLECIMIENTO'),
          TarjetaSuave(
            radio: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                FilaContacto(
                    icono: Icons.place_outlined,
                    etiqueta: 'Dirección',
                    valor: '${comercio.direccion}, ${comercio.ciudad}'),
                FilaContacto(
                    icono: Icons.schedule,
                    etiqueta: 'Horario de atención',
                    valor: comercio.horario),
                FilaContacto(
                    icono: Icons.local_shipping_outlined,
                    etiqueta: 'Servicio',
                    valor: comercio.servicio.label),
              ],
            ),
          ),

          // ══ CONTACTO ══
          const TituloSeccion(titulo: 'INFORMACIÓN DE CONTACTO'),
          TarjetaSuave(
            radio: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                FilaContacto(
                    icono: Icons.person_outline,
                    etiqueta: 'Dueño',
                    valor: profile.fullName),
                FilaContacto(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo electrónico',
                    valor: profile.email),
                FilaContacto(
                    icono: Icons.phone_iphone,
                    etiqueta: 'Teléfono del comercio',
                    valor:
                        comercio.telefono ?? profile.phone ?? 'No registrado'),
              ],
            ),
          ),

          // ══ CONFIGURACIÓN ══
          const TituloSeccion(titulo: 'CONFIGURACIÓN'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.fact_check_outlined,
                  titulo: 'Reportes de la comunidad',
                  subtitulo: 'Confirma o corrige precios reportados',
                  onTap: onReportesComunidad ??
                      () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.store_mall_directory_outlined,
                  titulo: 'Ajustes del Negocio',
                  subtitulo: 'Nombre, dirección y horario',
                  onTap: () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.help_outline,
                  titulo: 'Ayuda y Soporte',
                  onTap: () => mostrarProximamente(context)),
            ],
          ),
          const SizedBox(height: 24),
          BotonCerrarSesion(onConfirmar: onCerrarSesion),
        ],
      ),
    );
  }
}
