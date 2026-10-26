import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_state.dart';

/// Pantalla de bienvenida: "Selecciona tu perfil para continuar".
///
/// Elegir un perfil solo decide a qué login ir. Si Supabase ya guardó una
/// sesión en el dispositivo, `SessionBloc` la recupera: con un solo perfil
/// entramos directo a su Home, y con varios entramos directo al que se toque
/// si la cuenta lo tiene. En ambos casos el permiso sale de la base de datos,
/// no de lo que se toque aquí.
class ProfileSelectionPage extends StatelessWidget {
  const ProfileSelectionPage({super.key});

  /// Ancho máximo de la lista de botones en tablet y escritorio.
  static const double _maxContentWidth = 520;

  void _onSelect(BuildContext context, PerfilVisual perfil) {
    final profile = context.read<SessionBloc>().state.profile;
    if (profile != null && profile.hasRole(perfil.rol)) {
      context.goHome(role: perfil.rol, profile: profile);
    } else {
      Navigator.pushNamed(context, AppRoutes.login, arguments: perfil.rol);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (previous, current) =>
          previous.status != SessionStatus.authenticated &&
          current.status == SessionStatus.authenticated,
      listener: (context, state) {
        final profile = state.profile;
        if (profile != null && profile.roles.length == 1) {
          context.goHome(role: profile.roles.first, profile: profile);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3F8F6), Color(0xFFEDF2F0)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  children: [
                    BlocBuilder<SessionBloc, SessionState>(
                      buildWhen: (previous, current) =>
                          previous.status != current.status,
                      builder: (context, state) => SizedBox(
                        height: 4,
                        child: state.status == SessionStatus.loading
                            ? const LinearProgressIndicator()
                            : null,
                      ),
                    ),
                    const SizedBox(height: 76),
                    const Text('Bienvenido',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F5C3F))),
                    const SizedBox(height: 28),
                    const Text('Selecciona tu perfil para continuar',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF4F7A68))),
                    const SizedBox(height: 36),
                    for (final perfil in PerfilVisual.todos) ...[
                      _BotonPerfil(
                        perfil: perfil,
                        onTap: () => _onSelect(context, perfil),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de un perfil: ícono a la izquierda (coherente con su función), nombre
/// centrado y el color propio del perfil.
class _BotonPerfil extends StatelessWidget {
  final PerfilVisual perfil;
  final VoidCallback onTap;

  const _BotonPerfil({required this.perfil, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = perfil.paleta.primario;
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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: Icon(perfil.icono, size: 22, color: Colors.white),
            ),
            Expanded(child: Text(perfil.nombre, textAlign: TextAlign.center)),
            // Equilibra el ancho del ícono para que el nombre quede centrado.
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}
