import 'dart:async';

import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/get_solicitudes_pendientes_usecase.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/get_notificaciones_no_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/marcar_notificaciones_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

/// Repositorio de autenticación en memoria para las pruebas.
class FakeAuthRepository implements AuthRepository {
  AppUser? current;
  Object? signInError;
  Object? signUpError;

  /// Si se asigna, signIn/signUp esperan a que se complete (simula la red).
  Completer<void>? gate;

  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    signUpCalls++;
    await gate?.future;
    if (signUpError != null) throw signUpError!;
    current = AppUser(id: 'u1', email: email);
    return current!;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    signInCalls++;
    await gate?.future;
    if (signInError != null) throw signInError!;
    current = AppUser(id: 'u1', email: email);
    return current!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    current = null;
  }

  @override
  AppUser? currentUser() => current;
}

/// Repositorio de perfiles en memoria para las pruebas.
class FakeProfileRepository implements ProfileRepository {
  Profile? stored;
  Object? createError;
  Object? getError;
  Object? activateError;
  final created = <Profile>[];
  final collaboratorIds = <String>[];
  final courierIds = <String>[];
  int activateCalls = 0;
  Object? availabilityError;
  final availabilityCalls = <bool>[];

  @override
  Future<void> createProfile(Profile profile) async {
    if (createError != null) throw createError!;
    created.add(profile);
    stored = profile;
  }

  @override
  Future<void> createCollaboratorProfile(String userId) async {
    collaboratorIds.add(userId);
  }

  @override
  Future<void> createCourierProfile(String userId) async {
    courierIds.add(userId);
  }

  @override
  Future<void> activateCollaboratorMode(String userId) async {
    activateCalls++;
    if (activateError != null) throw activateError!;
    final current = stored!;
    stored = Profile(
      id: current.id,
      fullName: current.fullName,
      email: current.email,
      phone: current.phone,
      roles: {...current.roles, UserRole.colaborador},
      collaborator: CollaboratorStats.initial,
      courierStatus: current.courierStatus,
    );
  }

  @override
  Future<void> setCourierAvailability(bool available) async {
    if (availabilityError != null) throw availabilityError!;
    availabilityCalls.add(available);
  }

  @override
  Future<Profile> getProfile(String id) async {
    if (getError != null) throw getError!;
    return stored ??
        (throw const AuthFailure(
          'Tu cuenta no tiene un perfil registrado en SmartCart.',
        ));
  }
}

Profile profileWith(
  Set<UserRole> roles, {
  CollaboratorStats? collaborator,
  ApprovalStatus? courierStatus,
  bool courierAvailable = false,
  double? rating,
  int ratingCount = 0,
  DateTime? memberSince,
  String? courierRejectionReason,
}) =>
    Profile(
      id: 'u1',
      fullName: 'Ana María Gómez',
      email: 'ana@correo.com',
      phone: '+57 300 000 0000',
      roles: roles,
      collaborator: collaborator,
      courierStatus: courierStatus,
      courierAvailable: courierAvailable,
      rating: rating,
      ratingCount: ratingCount,
      memberSince: memberSince,
      courierRejectionReason: courierRejectionReason,
    );

/// Repositorio de comercios en memoria para las pruebas.
class FakeComercioRepository implements ComercioRepository {
  Comercio? stored;
  Object? getError;
  Object? registerError;
  int registerCalls = 0;

  @override
  Future<Comercio?> getMine(String userId) async {
    if (getError != null) throw getError!;
    return stored;
  }

  @override
  Future<Comercio> register(String userId, ComercioDatos datos) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    stored = Comercio(
      id: 'c1',
      nombre: datos.nombre,
      telefono: datos.telefono,
      direccion: datos.direccion,
      ciudad: datos.ciudad,
      horaApertura: datos.horaApertura,
      horaCierre: datos.horaCierre,
      servicio: datos.servicio,
      estado: ApprovalStatus.pendiente,
    );
    return stored!;
  }
}

/// Datos válidos del formulario de registro del comercio.
const comercioDatosValidos = ComercioDatos(
  nombre: 'Minimercado La Esquina',
  telefono: '+57 300 000 0000',
  direccion: 'Calle 10 # 5-20',
  ciudad: 'Cali, San Fernando',
  horaApertura: '07:00',
  horaCierre: '20:00',
  servicio: ServicioComercio.ambos,
);

/// Un comercio ya guardado con el [estado] indicado.
Comercio comercioConEstado(ApprovalStatus estado, {String? motivoRechazo}) =>
    Comercio(
      id: 'c1',
      nombre: 'Minimercado La Esquina',
      telefono: '+57 300 000 0000',
      direccion: 'Calle 10 # 5-20',
      ciudad: 'Cali, San Fernando',
      horaApertura: '07:00',
      horaCierre: '20:00',
      servicio: ServicioComercio.ambos,
      estado: estado,
      motivoRechazo: motivoRechazo,
    );

/// Una decisión que recibió [FakeSolicitudesRepository.decidir].
typedef DecisionRegistrada = ({Solicitud solicitud, bool aprobar, String? motivo});

/// Solicitudes pendientes en memoria (HU-24). Decidir una la quita de la
/// lista, como pasa en la base cuando deja de estar pendiente.
class FakeSolicitudesRepository implements SolicitudesRepository {
  final pendientesPorTipo = <TipoSolicitud, List<Solicitud>>{
    TipoSolicitud.comercio: [],
    TipoSolicitud.repartidor: [],
  };
  final decisiones = <DecisionRegistrada>[];
  final pedidos = <(TipoSolicitud, PageRequest)>[];
  Object? listError;
  Object? decidirError;

  @override
  Future<PagedResult<Solicitud>> pendientes(
    TipoSolicitud tipo,
    PageRequest request,
  ) async {
    pedidos.add((tipo, request));
    if (listError != null) throw listError!;
    final todas = pendientesPorTipo[tipo]!;
    // Igual que `range(from, to)`: el `to` es inclusivo.
    final filas = todas.skip(request.from).take(request.pageSize + 1).toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<void> decidir(
    Solicitud solicitud, {
    required bool aprobar,
    String? motivo,
  }) async {
    if (decidirError != null) throw decidirError!;
    decisiones.add((solicitud: solicitud, aprobar: aprobar, motivo: motivo));
    pendientesPorTipo[solicitud.tipo]!.removeWhere((s) => s.id == solicitud.id);
  }
}

/// Notificaciones en memoria.
class FakeNotificacionRepository implements NotificacionRepository {
  final noLeidasList = <Notificacion>[];
  final marcadas = <String>[];
  Object? getError;

  @override
  Future<List<Notificacion>> noLeidas(String userId) async {
    if (getError != null) throw getError!;
    return List.of(noLeidasList);
  }

  @override
  Future<void> marcarLeidas(List<String> ids) async {
    marcadas.addAll(ids);
    noLeidasList.removeWhere((n) => ids.contains(n.id));
  }
}

/// Solicitud pendiente de un comercio.
Solicitud solicitudComercio({String id = 'c1', String nombre = 'Minimercado La Esquina'}) =>
    Solicitud(
      tipo: TipoSolicitud.comercio,
      id: id,
      idUsuario: 'dueno-$id',
      nombre: nombre,
      responsable: 'Pedro Pérez',
      correo: 'pedro@correo.com',
      telefono: '+57 300 000 0000',
      creadoEn: DateTime(2026, 11, 2),
      comercio: comercioConEstado(ApprovalStatus.pendiente),
    );

/// Solicitud pendiente de un repartidor.
Solicitud solicitudRepartidor({String id = 'r1', String nombre = 'Luis Torres'}) =>
    Solicitud(
      tipo: TipoSolicitud.repartidor,
      id: id,
      idUsuario: id,
      nombre: nombre,
      responsable: nombre,
      correo: 'luis@correo.com',
      creadoEn: DateTime(2026, 11, 3),
    );

/// Agrupa los dobles y construye los Blocs con ellos.
class TestEnv {
  final auth = FakeAuthRepository();
  final profiles = FakeProfileRepository();
  final comercios = FakeComercioRepository();
  final solicitudes = FakeSolicitudesRepository();
  final notificaciones = FakeNotificacionRepository();

  DecidirSolicitudUseCase get decidirSolicitud => DecidirSolicitudUseCase(
      auth: auth, profiles: profiles, solicitudes: solicitudes);
  GetSolicitudesPendientesUseCase get getPendientes =>
      GetSolicitudesPendientesUseCase(solicitudes: solicitudes);

  /// Deja la sesión iniciada con una cuenta que tiene los [roles].
  void iniciarSesionCon(Set<UserRole> roles) {
    auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    profiles.stored = profileWith(roles);
  }

  DecisionSolicitudBloc decisionBloc(Solicitud solicitud) =>
      DecisionSolicitudBloc(solicitud: solicitud, decidir: decidirSolicitud);
  PaginatedBloc<Solicitud> listaBloc(TipoSolicitud tipo, {int pageSize = 20}) =>
      PaginatedBloc<Solicitud>(
        fetchPage: (request) => getPendientes(tipo, request),
        pageSize: pageSize,
      );
  NotificacionesBloc notificacionesBloc() => NotificacionesBloc(
        noLeidas: GetNotificacionesNoLeidasUseCase(
            auth: auth, notificaciones: notificaciones),
        marcarLeidas:
            MarcarNotificacionesLeidasUseCase(notificaciones: notificaciones),
      );

  SignInUseCase get signIn => SignInUseCase(auth: auth, profiles: profiles);
  SignUpUseCase get signUp => SignUpUseCase(auth: auth, profiles: profiles);
  ActivarModoColaboradorUseCase get activarColaborador =>
      ActivarModoColaboradorUseCase(auth: auth, profiles: profiles);
  RegistrarComercioUseCase get registrarComercio =>
      RegistrarComercioUseCase(auth: auth, comercios: comercios);
  GetMiComercioUseCase get getMiComercio =>
      GetMiComercioUseCase(auth: auth, comercios: comercios);

  LoginBloc loginBloc() => LoginBloc(signIn: signIn);
  RegisterBloc registerBloc() => RegisterBloc(signUp: signUp);
  SessionBloc sessionBloc() => SessionBloc(
        getMyProfile: GetMyProfileUseCase(auth: auth, profiles: profiles),
        signOut: SignOutUseCase(auth: auth),
      );
  CambiarDisponibilidadUseCase get cambiarDisponibilidad =>
      CambiarDisponibilidadUseCase(auth: auth, profiles: profiles);
  DisponibilidadBloc disponibilidadBloc({bool inicial = false}) =>
      DisponibilidadBloc(cambiar: cambiarDisponibilidad, inicial: inicial);

  ColaboradorOnboardingBloc colaboradorBloc() =>
      ColaboradorOnboardingBloc(activar: activarColaborador);
  ComercioBloc comercioBloc() =>
      ComercioBloc(getMine: getMiComercio, registrar: registrarComercio);
}
