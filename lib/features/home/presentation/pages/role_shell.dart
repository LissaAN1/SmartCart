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
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';
import 'package:smartcart/features/comercio/presentation/widgets/comercio_gate.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
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

  /// HU-14: crea la lista de los últimos reportes del colaborador para su
  /// Home. Sin ella (por ejemplo en las pruebas de navegación) el Home
  /// muestra el historial vacío.
  final PaginatedBloc<MiReporte> Function()? crearMisReportes;

  const RolShell({
    super.key,
    required this.rol,
    required this.profile,
    this.crearMisReportes,
  });

  @override
  State<RolShell> createState() => _RolShellState();
}

class _RolShellState extends State<RolShell> {
  bool _enPerfil = false;
  late Profile _profile = widget.profile;

  /// HU-14: últimos reportes del colaborador. Se crea y se cierra aquí, y se
  /// recarga al volver del flujo de reporte para que el nuevo aparezca.
  PaginatedBloc<MiReporte>? _misReportes;

  @override
  void initState() {
    super.initState();
    _misReportes = widget.crearMisReportes?.call()?..add(PaginatedStarted());
  }

  @override
  void dispose() {
    _misReportes?.close();
    super.dispose();
  }

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

  /// Pestaña "Catálogo" del comercio (HU-10).
  static const _tabCatalogoComercio = 2;

  /// Pestaña "Reportar Precio" del colaborador (HU-14).
  static const _tabReportarColaborador = 2;

  void _onTab(int i) {
    if (_tema == RolTema.admin && i == _tabAprobarAdmin) {
      _abrirAprobaciones();
      return;
    }
    if (_tema == RolTema.comercio && i == _tabCatalogoComercio) {
      _abrirCatalogo();
      return;
    }
    if (_tema == RolTema.colaborador && i == _tabReportarColaborador) {
      _abrirReportePrecio();
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

  /// HU-14: primer paso del reporte de precio. Al volver (con o sin reporte
  /// enviado) se recarga el historial: es barato y evita mostrar uno viejo.
  Future<void> _abrirReportePrecio() async {
    await Navigator.of(context).pushNamed(AppRoutes.reporteEstablecimiento);
    if (mounted) _recargarMisReportes();
  }

  void _recargarMisReportes() => _misReportes?.add(PaginatedStarted());

  /// HU-14: historial completo de reportes del colaborador.
  Future<void> _abrirMisReportes() async {
    await Navigator.of(context).pushNamed(AppRoutes.misReportes);
    if (mounted) _recargarMisReportes();
  }

  /// HU-10: lista de productos del comercio.
  void _abrirCatalogo() => Navigator.of(context).pushNamed(AppRoutes.catalogo);

  /// HU-10: formulario para agregar un producto nuevo. Al volver no hace
  /// falta recargar nada aquí: el catálogo se carga al abrirse.
  void _nuevoProducto() =>
      Navigator.of(context).pushNamed(AppRoutes.catalogoProducto);

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
          profile: p,
          onActivarColaborador: _activarColaborador),
      (RolTema.colaborador, false) => _conMisReportes(),
      (RolTema.colaborador, true) => ColaboradorPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p),
      // Aquí solo llega un repartidor aprobado (ver `build`).
      (RolTema.repartidor, false) => _conDisponibilidad(
          (disponible, cambiar) => RepartidorHomeScreen(
              onTab: _onTab, enLinea: disponible, onCambioDisponible: cambiar)),
      (RolTema.repartidor, true) => RepartidorPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p),
      (RolTema.comercio, false) => _conComercioHome(),
      (RolTema.comercio, true) => _conComercio((c) => ComercioPerfilScreen(
          onTab: _onTab, onCerrarSesion: _salir, profile: p, comercio: c)),
      (RolTema.admin, false) => AdminHomeScreen(
          onTab: _onTab,
          nombre: p.fullName,
          onAbrirAprobaciones: _abrirAprobaciones),
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

  /// Home del colaborador con sus últimos reportes reales (HU-14), incluidos
  /// los pendientes.
  Widget _conMisReportes() {
    Widget home(PaginatedState<MiReporte> estado) {
      final cargando = estado.status == PaginatedStatus.initial ||
          estado.status == PaginatedStatus.loading;
      return ColaboradorHomeScreen(
        onTab: _onTab,
        nombre: _primerNombre,
        onReportarPrecio: _abrirReportePrecio,
        reportes: estado.items,
        cargandoReportes: _misReportes != null && cargando,
        errorReportes: estado.status == PaginatedStatus.failure
            ? estado.errorMessage
            : null,
        onReintentarReportes: _recargarMisReportes,
        onVerHistorial: _misReportes == null ? null : _abrirMisReportes,
      );
    }

    final bloc = _misReportes;
    if (bloc == null) return home(PaginatedState<MiReporte>());
    return BlocBuilder<PaginatedBloc<MiReporte>, PaginatedState<MiReporte>>(
      bloc: bloc,
      builder: (context, estado) => home(estado),
    );
  }

  /// Home del comercio aprobado. Además de los accesos, avisa si falta la
  /// ubicación del comercio y deja guardarla (HU-14).
  Widget _conComercioHome() {
    return BlocBuilder<ComercioBloc, ComercioState>(
      builder: (context, state) {
        final comercio = state.comercio;
        if (comercio == null) return const SizedBox.shrink();
        return ComercioHomeScreen(
          onTab: _onTab,
          nombreComercio: comercio.nombre,
          onAbrirCatalogo: _abrirCatalogo,
          onNuevoProducto: _nuevoProducto,
          sinUbicacion: !comercio.tieneUbicacion,
          ubicando: state.status == ComercioStatus.locating,
          errorUbicacion: state.status == ComercioStatus.locationFailed
              ? state.errorMessage
              : null,
          onFijarUbicacion: () =>
              context.read<ComercioBloc>().add(ComercioUbicacionSolicitada()),
        );
      },
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
