// lib/src/features/admin/ui/screens/admin_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/admin_widgets.dart';

class AdminPerfilScreen extends StatelessWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  const AdminPerfilScreen({super.key, this.onTab, this.onCerrarSesion});

  @override
  Widget build(BuildContext context) {
    final t = TemaRol.admin;
    return PantallaRol(
      tema: t,
      navItems: navAdmin(pendientes: 12),
      tabActiva: 5,
      onTab: onTab,
      barraSuperior: const BarraTituloRol(titulo: 'Mi Perfil'),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          EncabezadoPerfil(
            nombre: 'Carlos Mendoza',
            insignia: Icons.admin_panel_settings_outlined,
            ubicacion: 'Bogotá, Colombia',
            etiquetas: [EtiquetaEstado.marca('Super Administrador')],
          ),
          const SizedBox(height: 22),

          // ══ ACTIVIDAD SEMANAL ══
          TarjetaSuave(
            radio: 24,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actividad semanal',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: t.texto)),
                Text('Solicitudes gestionadas por día',
                    style: TextStyle(fontSize: 13, color: t.textoGris)),
                const SizedBox(height: 18),
                const GraficoBarrasSemana(
                    valores: [42, 57, 34, 71, 49, 27, 14]),
              ],
            ),
          ),

          // ══ GESTIÓN ══
          const TituloSeccion(titulo: 'GESTIÓN DE PLATAFORMA'),
          GrupoMenu(
            items: [
              ItemMenu(
                  icono: Icons.people_outline,
                  titulo: 'Gestionar cadenas registradas',
                  subtitulo: 'Ver y administrar cadenas',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.extension_outlined,
                  titulo: 'Integraciones',
                  subtitulo: 'Configurar servicios de terceros',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.settings_outlined,
                  titulo: 'Ajustes',
                  subtitulo: 'Preferencias generales del sistema',
                  onTap: () {}),
            ],
          ),

          // ══ CONTACTO ══
          const TituloSeccion(titulo: 'INFORMACIÓN DE CONTACTO'),
          const TarjetaSuave(
            radio: 22,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                FilaContacto(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo electrónico',
                    valor: 'c.mendoza@smartcart.com.co'),
                FilaContacto(
                    icono: Icons.phone_iphone,
                    etiqueta: 'Teléfono de contacto',
                    valor: '+57 310 456 7890'),
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
