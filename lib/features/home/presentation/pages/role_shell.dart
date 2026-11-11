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
import 'package:smartcart/features/comercio/comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
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
  int _tab = 0;
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

  /// Pestañas con pantalla: Home (0), Perfil y, para el administrador,
  /// Aprobar (1, HU-24).
  bool _tieneTab(int i) =>
      i == 0 ||
      i == _tabPerfil ||
      (_tema == RolTema.admin && i == _tabAprobar);

  static const _tabAprobar = 1;

  void _onTab(int i) {
    if (!_tieneTab(i)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Pantalla aún no disponible')));
      return;
    }
    setState(() => _tab = i);
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
          // Resultado de "Actualizar estado" (SessionRefreshed).
          setState(() => _profile = state.profile!);
        } else if (state.status == SessionStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'No pudimos cerrar la sesión.')));
        }
      },
      child: _tema == RolTema.comercio
          ? ComercioGate(onCerrarSesion: _salir, child: _pantalla())
          : _pantalla(),
    );
  }

  /// Sin dato se asume pendiente: es lo más restrictivo (HU-08).
  ApprovalStatus get _estadoRepartidor =>
      _profile.courierStatus ?? ApprovalStatus.pendiente;

  Widget _pantalla() {
    final p = _profile;
    // HU-08: hasta que el administrador lo apruebe, el repartidor solo ve la
    // pantalla de espera (sin Home ni Perfil).
    if (_tema == RolTema.repartidor &&
        _estadoRepartidor != ApprovalStatus.aprobado) {
      return BlocBuilder<SessionBloc, SessionState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, session) => RepartidorEstadoPage(
          estado: _estadoRepartidor,
          actualizando: session.status == SessionStatus.loading,
          onActualizar: () =>
              context.read<SessionBloc>().add(SessionRefreshed()),
          onCerrarSesion: _salir,
        ),
      );
    }
    if (_tema == RolTema.admin && _tab == _tabAprobar) {
      return AdminAprobacionesScreen(onTab: _onTab);
    }
    return switch ((_tema, _tab == _tabPerfil)) {
      (RolTema.cliente, false) =>
        ClienteHomeScreen(onTab: _onTab, nombre: _primerNombre),
      (RolTema.cliente, true) => ClientePerfilScreen(
          onTab: _onTab,
          onCerrarSesion: _salir,
          profile: p,
          onActivarColaborador: _activarColaborador),
      (RolTema.colaborador, false) =>
        ColaboradorHomeScreen(onTab: _onTab, nombre: _primerNombre),
      (RolTema.colaborador, true) => ColaboradorPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p),
      (RolTema.repartidor, false) => _conDisponibilidad(
          (disponible, cambiar) => RepartidorHomeScreen(
              onTab: _onTab, enLinea: disponible, onCambioDisponible: cambiar)),
      (RolTema.repartidor, true) => RepartidorPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p),
      (RolTema.comercio, false) => _conComercio((c) =>
          ComercioHomeScreen(onTab: _onTab, nombreComercio: c.nombre)),
      (RolTema.comercio, true) => _conComercio((c) => ComercioPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p, comercio: c)),
      (RolTema.admin, false) =>
        AdminHomeScreen(onTab: _onTab, nombre: p.fullName),
      (RolTema.admin, true) => AdminPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p),
    };
  }

  /// Home del repartidor con su disponibilidad real (la guarda
  /// `DisponibilidadBloc`); si falla el guardado avisa y conserva el valor.
  Widget _conDisponibilidad(
    Widget Function(bool disponible, ValueChanged<bool>? cambiar) builder,
  ) {
    return BlocConsumer<DisponibilidadBloc, DisponibilidadState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) => builder(
        state.disponible,
        state.guardando
            ? null
            : (v) => context
                .read<DisponibilidadBloc>()
                .add(DisponibilidadCambiada(v)),
      ),
    );
  }

  /// Pantalla del comercio aprobado con sus datos reales. `ComercioGate` ya
  /// garantiza que existe; si por algún motivo no, no se muestra nada.
  Widget _conComercio(Widget Function(Comercio comercio) builder) {
    return BlocBuilder<ComercioBloc, ComercioState>(
      builder: (context, state) {
        final comercio = state.comercio;
        return comercio == null ? const SizedBox.shrink() : builder(comercio);
      },
    );
  }
}