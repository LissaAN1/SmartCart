import 'package:flutter/material.dart';
import '../../../../core/ui/roles/roles_ui.dart';
import '../../../admin/admin.dart';
import '../../../cliente/cliente.dart';
import '../../../colaborador/colaborador.dart';
import '../../../comercio/comercio.dart';
import '../../../repartidor/repartidor.dart';

/// Pantalla base (simula usuario ya registrado). "Bienvenido / Selecciona tu perfil para continuar".
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _roles = [
    (RolTema.cliente, 'Cliente'),
    (RolTema.colaborador, 'Colaborador'),
    (RolTema.comercio, 'Comercio'),
    (RolTema.repartidor, 'Repartidor'),
    (RolTema.admin, 'Administrador'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F8F6), Color(0xFFEDF2F0)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            children: [
              const SizedBox(height: 80),
              const Text('Bienvenido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F5C3F))),
              const SizedBox(height: 28),
              const Text('Selecciona tu perfil para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF4F7A68))),
              const SizedBox(height: 36),
              for (final (rol, nombre) in _roles) ...[
                _BotonRol(
                  texto: nombre,
                  color: TemaRol.de(rol).primario,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RolShell(rol: rol)),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonRol extends StatelessWidget {
  final String texto;
  final Color color;
  final VoidCallback onTap;
  const _BotonRol(
      {required this.texto, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(64),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: Text(texto),
      ),
    );
  }
}

/// Alterna entre Home y Perfil según la pestaña tocada. Las demás
/// pestañas no tienen pantalla todavía.
class RolShell extends StatefulWidget {
  final RolTema rol;
  const RolShell({super.key, required this.rol});

  @override
  State<RolShell> createState() => _RolShellState();
}

class _RolShellState extends State<RolShell> {
  bool _enPerfil = false;

  // Índice de la pestaña "Perfil" en la barra de cada rol.
  int get _tabPerfil => switch (widget.rol) {
        RolTema.cliente => 3,
        RolTema.colaborador => 3,
        RolTema.repartidor => 2,
        RolTema.comercio => 4,
        RolTema.admin => 5,
      };

  void _onTab(int i) {
    final perfil = i == _tabPerfil;
    if (!perfil && i != 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Pantalla aún no disponible')));
      return;
    }
    setState(() => _enPerfil = perfil);
  }

  // TODO(auth): llamar aquí a signOut de Supabase.
  void _salir() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return switch ((widget.rol, _enPerfil)) {
      (RolTema.cliente, false) => ClienteHomeScreen(onTab: _onTab),
      (RolTema.cliente, true) =>
        ClientePerfilScreen(onTab: _onTab, onCerrarSesion: _salir),
      (RolTema.colaborador, false) => ColaboradorHomeScreen(onTab: _onTab),
      (RolTema.colaborador, true) =>
        ColaboradorPerfilScreen(onTab: _onTab, onCerrarSesion: _salir),
      (RolTema.repartidor, false) => RepartidorHomeScreen(onTab: _onTab),
      (RolTema.repartidor, true) =>
        RepartidorPerfilScreen(onTab: _onTab, onCerrarSesion: _salir),
      (RolTema.comercio, false) => ComercioHomeScreen(onTab: _onTab),
      (RolTema.comercio, true) =>
        ComercioPerfilScreen(onTab: _onTab, onCerrarSesion: _salir),
      (RolTema.admin, false) => AdminHomeScreen(onTab: _onTab),
      (RolTema.admin, true) =>
        AdminPerfilScreen(onTab: _onTab, onCerrarSesion: _salir),
    };
  }
}
