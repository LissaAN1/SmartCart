// lib/src/features/admin/ui/screens/admin_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../auth/domain/entities/profile.dart';
import '../widgets/admin_widgets.dart';

class AdminPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  final Profile profile;
  const AdminPerfilScreen({
    super.key,
    this.onTab,
    this.onCerrarSesion,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    return PantallaRol(
      tema: t,
      navItems: navAdmin(),
      tabActiva: 5,
      onTab: onTab,
      barraSuperior: const BarraTituloRol(titulo: 'Mi Perfil'),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: profile.fullName,
            insignia: Icons.admin_panel_settings_outlined,
            etiquetas: [
              EtiquetaEstado.marca('Administrador'),
              if (profile.memberSince != null)
                EtiquetaEstado.marca('Desde ${mesYAnio(profile.memberSince!)}'),
            ],
          ),
          const SizedBox(height: 22),

          // ══ GESTIÓN ══
          const TituloSeccion(titulo: 'GESTIÓN DE PLATAFORMA'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.people_outline,
                  titulo: 'Gestionar cadenas registradas',
                  subtitulo: 'Ver y administrar cadenas',
                  onTap: () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.extension_outlined,
                  titulo: 'Integraciones',
                  subtitulo: 'Configurar servicios de terceros',
                  onTap: () => mostrarProximamente(context)),
              ItemMenu(
                  icono: Icons.settings_outlined,
                  titulo: 'Ajustes',
                  subtitulo: 'Preferencias generales del sistema',
                  onTap: () => mostrarProximamente(context)),
            ],
          ),

          // ══ CONTACTO ══
          const TituloSeccion(titulo: 'INFORMACIÓN DE CONTACTO'),
          TarjetaSuave(
            radio: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                FilaContacto(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo electrónico',
                    valor: profile.email),
                FilaContacto(
                    icono: Icons.phone_iphone,
                    etiqueta: 'Teléfono de contacto',
                    valor: profile.phone ?? 'No registrado'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          BotonCerrarSesion(onConfirmar: onCerrarSesion),
        ],
      ),
    );
  }
}
