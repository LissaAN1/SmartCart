import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/admin/admin.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/cliente/cliente.dart';
import 'package:smartcart/features/colaborador/colaborador.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/comercio/comercio.dart';
import 'package:smartcart/features/comercio/presentation/widgets/comercio_gate.dart';
import 'package:smartcart/features/repartidor/repartidor.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_event.dart';
import 'package:smartcart/features/session/ui/bloc/session_state.dart';

/// Aloja el Home y el Perfil del perfil con el que entró la persona y alterna
/// entre ellos según la pestaña tocada. Las demás pestañas no tienen pantalla
/// todavía. Recibe quién es la persona ya autenticada y se encarga de cerrar
/// la sesión.
///
/// Guarda su propia copia del perfil porque puede cambiar mientras está
/// abierto: al activar el modo Colaborador (HU-06) se agrega ese rol.
class RolShell extends StatefulWidget {
  final UserRole rol;
  final Profile profile;

  const RolShell({super.key, required this.rol, required this.profile});

  @override
  State<RolShell> createState() => _RolShellState();
}

class _RolShellState extends State<RolShell> {
  bool _enPerfil = false;
  late Profile _profile = widget.profile;

  RolTema get _tema => PerfilVisual.de(widget.rol).tema;

  String get _primerNombre {
    final partes = _profile.fullName.trim().split(RegExp(r'\s+'));
    return partes.first;
  }

  // Índice de la pestaña "Perfil" en la barra de cada rol.
  int get _tabPerfil => switch (_tema) {
        RolTema.cliente => 3,
        RolTema.colaborador => 3,
        RolTema.repartidor => 2,
        RolTema.comercio => 4,
        RolTema.admin => 5,
      };

  /// Pestaña "Aprobar" del administrador (HU-24).
  static const _tabAprobarAdmin = 1;

  void _onTab(int i) {
    if (_tema == RolTema.admin && i == _tabAprobarAdmin) {
      _abrirAprobaciones();
      return;
    }
    final perfil = i == _tabPerfil;
    if (!perfil && i != 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Pantalla aún no disponible')));
      return;
    }
    setState(() => _enPerfil = perfil);
  }

  /// HU-06: abre el onboarding y, si la persona activó el modo, se queda con
  /// el perfil actualizado (ya con el rol colaborador).
  Future<void> _activarColaborador() async {
    final actualizado =
        await Navigator.of(context).pushNamed<Profile>(AppRoutes.colaboradorOnboarding);
    if (actualizado != null && mounted) {
      setState(() => _profile = actualizado);
    }
  }

  /// HU-24: lista de comercios y repartidores pendientes de aprobación.
  void _abrirAprobaciones() =>
      Navigator.of(context).pushNamed(AppRoutes.adminSolicitudes);

  void _salir() => context.read<SessionBloc>().add(SignOutRequested());

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SessionStatus.unauthenticated) {
          context.goInicio();
        } else if (state.status == SessionStatus.authenticated &&
            state.profile != null) {
          // Perfil releído con "Actualizar estado" (por ejemplo, el
          // administrador ya aprobó al repartidor).
          setState(() => _profile = state.profile!);
        } else if (state.status == SessionStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'No pudimos cerrar la sesión.')));
        }
      },
      child: switch (_tema) {
        RolTema.comercio =>
          ComercioGate(onCerrarSesion: _salir, child: _pantalla()),
        // HU-08: un repartidor sin aprobar solo ve el estado de su registro;
        // ni el Home ni el Perfil (ni la barra para llegar a ellos).
        RolTema.repartidor when _estadoRepartidor != ApprovalStatus.aprobado =>
          _estadoRegistroRepartidor(),
        _ => _pantalla(),
      },
    );
  }

  /// Sin dato se asume pendiente: es lo más restrictivo (HU-08).
  ApprovalStatus get _estadoRepartidor =>
      _profile.courierStatus ?? ApprovalStatus.pendiente;

  Widget _estadoRegistroRepartidor() {
    final actualizando = context.select<SessionBloc, bool>(
      (bloc) => bloc.state.status == SessionStatus.loading,
    );
    return RepartidorEstadoPage(
      estado: _estadoRepartidor,
      nombre: _profile.fullName,
      correo: _profile.email,
      telefono: _profile.phone,
      motivoRechazo: _profile.courierRejectionReason,
      actualizando: actualizando,
      onActualizar: () =>
          context.read<SessionBloc>().add(ProfileRefreshRequested()),
      onCerrarSesion: _salir,
    );
  }

  Widget _pantalla() {
    final p = _profile;
    return switch ((_tema, _enPerfil)) {
      (RolTema.cliente, false) =>
        ClienteHomeScreen(onTab: _onTab, nombre: _primerNombre),
      (RolTema.cliente, true) => ClientePerfilScreen(
          onTab: _onTab,
          onCerrarSesion: _salir,
          nombre: p.fullName,
          correo: p.email,
          esColaborador: p.hasRole(UserRole.colaborador),
          estadisticasColaborador: p.collaborator ?? CollaboratorStats.initial,
          onActivarColaborador: _activarColaborador),
      (RolTema.colaborador, false) =>
        ColaboradorHomeScreen(onTab: _onTab, nombre: _primerNombre),
      (RolTema.colaborador, true) => ColaboradorPerfilScreen(
          onTab: _onTab,
          onCerrarSesion: _salir,
          nombre: p.fullName,
          estadisticas: p.collaborator ?? CollaboratorStats.initial),
      // Aquí solo llega un repartidor aprobado (ver `build`).
      (RolTema.repartidor, false) => RepartidorHomeScreen(onTab: _onTab),
      (RolTema.repartidor, true) => RepartidorPerfilScreen(
          onTab: _onTab,
          onCerrarSesion: _salir,
          nombre: p.fullName,
          estado: _estadoRepartidor),
      (RolTema.comercio, false) => ComercioHomeScreen(onTab: _onTab),
      (RolTema.comercio, true) =>
        ComercioPerfilScreen(onTab: _onTab, onCerrarSesion: _salir),
      (RolTema.admin, false) => AdminHomeScreen(
          onTab: _onTab,
          nombre: p.fullName,
          onAbrirAprobaciones: _abrirAprobaciones),
      (RolTema.admin, true) => AdminPerfilScreen(
          onTab: _onTab,
          onCerrarSesion: _salir,
          nombre: p.fullName,
          correo: p.email,
          telefono: p.phone),
    };
  }
}
