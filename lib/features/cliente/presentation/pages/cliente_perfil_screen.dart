// lib/src/features/cliente/ui/screens/cliente_perfil_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../widgets/cliente_widgets.dart';

class ClientePerfilScreen extends StatefulWidget {
  final ValueChanged<int>? onTab;
  final VoidCallback? onCerrarSesion;
  final String nombre;
  final String correo;
  const ClientePerfilScreen({
    super.key,
    this.onTab,
    this.onCerrarSesion,
    required this.nombre,
    required this.correo,
  });

  @override
  State<ClientePerfilScreen> createState() => _ClientePerfilScreenState();
}

class _ClientePerfilScreenState extends State<ClientePerfilScreen> {
  bool _modoColaborador = false;

  @override
  Widget build(BuildContext context) {
    return PantallaRol(
      tema: TemaRol.cliente,
      navItems: navCliente(itemsCarrito: 3),
      tabActiva: 3,
      onTab: widget.onTab,
      barraSuperior: const BarraMarca(
        sobretitulo: 'SMARTCART',
        titulo: 'Mi Perfil',
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // ══ CABECERA ══
          CabeceraPerfilCliente(
            nombre: widget.nombre,
            correo: widget.correo,
            etiquetas: [
              EtiquetaEstado.marca('Cliente'),
            ],
          ),
          const SizedBox(height: 26),

          // ══ MODO COLABORADOR ══
          TarjetaInterruptor(
            icono: Icons.work_outline,
            titulo: 'MODO COLABORADOR',
            subtitulo: 'Ayuda a otros con sus compras',
            valor: _modoColaborador,
            onCambio: (v) => setState(() => _modoColaborador = v),
          ),

          // ══ ACTIVIDAD ══
          const TituloSeccion(titulo: 'ACTIVIDAD Y GESTIÓN'),
          GrupoMenu(
            conTarjeta: false,
            items: [
              ItemMenu(
                  icono: Icons.history,
                  titulo: 'Historial de compras',
                  subtitulo: 'Ver transacciones pasadas',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.chat_bubble_outline,
                  titulo: 'Reportar una queja',
                  subtitulo: 'Soporte técnico e incidencias',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.credit_card,
                  titulo: 'Métodos de pago',
                  subtitulo: 'Visa **** 4242',
                  onTap: () {}),
            ],
          ),

          // ══ PREFERENCIAS ══
          const TituloSeccion(titulo: 'PREFERENCIAS'),
          GrupoMenu(
            conTarjeta: false,
            items: [
              ItemMenu(
                  icono: Icons.notifications_none,
                  titulo: 'Notificaciones',
                  subtitulo: 'Alertas y promociones',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.settings_outlined,
                  titulo: 'Ajustes de cuenta',
                  subtitulo: 'Privacidad y seguridad',
                  onTap: () {}),
              ItemMenu(
                  icono: Icons.help_outline,
                  titulo: 'Ayuda y Soporte',
                  onTap: () {}),
              ItemMenu(
                icono: Icons.logout,
                titulo: 'Cerrar sesión',
                peligro: true,
                onTap: () =>
                    confirmarCierreSesion(context, widget.onCerrarSesion),
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
