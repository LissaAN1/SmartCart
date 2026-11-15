import 'package:get_it/get_it.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/data/repository/solicitudes_repository_impl.dart';
import 'package:smartcart/features/aprobaciones/data/source/supabase_solicitudes_data_source.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/get_solicitudes_pendientes_usecase.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/notificaciones/data/repository/notificacion_repository_impl.dart';
import 'package:smartcart/features/notificaciones/data/source/supabase_notificacion_data_source.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/get_notificaciones_no_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/marcar_notificaciones_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/data/repository/auth_repository_impl.dart';
import 'package:smartcart/features/auth/data/repository/profile_repository_impl.dart';
import 'package:smartcart/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:smartcart/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';
import 'package:smartcart/features/catalog/data/repository/catalogo_repository_impl.dart';
import 'package:smartcart/features/catalog/data/source/file_picker_selector_csv.dart';
import 'package:smartcart/features/catalog/data/source/supabase_catalogo_data_source.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';
import 'package:smartcart/features/catalog/domain/usecases/cargar_productos_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_archivo_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_categorias_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_productos_usecase.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/data/repository/comercio_repository_impl.dart';
import 'package:smartcart/features/comercio/data/source/supabase_comercio_data_source.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/domain/usecases/fijar_ubicacion_comercio_usecase.dart';
import 'package:smartcart/features/reportes/data/repository/reportes_repository_impl.dart';
import 'package:smartcart/features/reportes/data/source/image_picker_selector_foto.dart';
import 'package:smartcart/features/reportes/data/source/supabase_reportes_data_source.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/reportes/domain/repository/selector_foto.dart';
import 'package:smartcart/features/reportes/domain/usecases/buscar_productos_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/enviar_reporte_precio_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_establecimientos_cercanos_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_mis_reportes_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/sugerir_establecimiento_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/tomar_foto_usecase.dart';
import 'package:smartcart/features/reportes/presentation/bloc/reporte_form_bloc.dart';
import 'package:smartcart/features/reportes/presentation/bloc/sugerencia_bloc.dart';
import 'package:smartcart/features/ubicacion/data/source/geolocator_servicio_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/servicio_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Localizador de servicios (patrón Service Locator) de la app.
///
/// Es el único lugar que conoce las clases concretas. La cadena de cada
/// funcionalidad se registra de adentro hacia afuera:
/// cliente -> DataSource -> RepositoryImpl -> UseCase -> Bloc.
///
/// Las pantallas y el `AppRouter` piden lo que necesitan con `sl<LoginBloc>()`
/// y nunca construyen las dependencias a mano.
final GetIt sl = GetIt.instance;

/// Nombres de los registros que comparten tipo con otro (ver
/// `PaginatedBloc<Producto>`).
abstract final class InstanciasSl {
  /// HU-14: lista de productos de un establecimiento filtrada por consulta.
  static const busquedaProductos = 'busqueda-productos-reporte';
}

/// Registra todas las dependencias. Se llama una sola vez en `main`, después
/// de `Supabase.initialize`. Llamarla de nuevo no duplica los registros.
void setupDependencies() {
  if (sl.isRegistered<SupabaseClient>()) return;

  // ── Infraestructura ──
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<SupabaseAuthDataSource>(
    () => SupabaseAuthDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseProfileDataSource>(
    () => SupabaseProfileDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseComercioDataSource>(
    () => SupabaseComercioDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseSolicitudesDataSource>(
    () => SupabaseSolicitudesDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseNotificacionDataSource>(
    () => SupabaseNotificacionDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseCatalogoDataSource>(
    () => SupabaseCatalogoDataSource(client: sl()),
  );
  // HU-10: se registra con el tipo del contrato; solo esta línea conoce
  // `file_picker`.
  sl.registerLazySingleton<SelectorArchivoCsv>(() => FilePickerSelectorCsv());
  sl.registerLazySingleton<SupabaseReportesDataSource>(
    () => SupabaseReportesDataSource(client: sl()),
  );
  // HU-14: el GPS y la cámara se registran con el tipo del contrato; solo
  // estas líneas conocen `geolocator`, `image_picker` y `permission_handler`.
  sl.registerLazySingleton<ServicioUbicacion>(() => GeolocatorServicioUbicacion());
  sl.registerLazySingleton<SelectorFoto>(() => ImagePickerSelectorFoto());

  // ── Repositorios: se registran con el tipo del contrato del dominio ──
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ComercioRepository>(
    () => ComercioRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<SolicitudesRepository>(
    () => SolicitudesRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<NotificacionRepository>(
    () => NotificacionRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<CatalogoRepository>(
    () => CatalogoRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ReportesRepository>(
    () => ReportesRepositoryImpl(dataSource: sl()),
  );

  // ── Casos de uso ──
  sl.registerLazySingleton(() => SignInUseCase(auth: sl(), profiles: sl()));
  sl.registerLazySingleton(() => SignUpUseCase(auth: sl(), profiles: sl()));
  sl.registerLazySingleton(
    () => GetMyProfileUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(() => SignOutUseCase(auth: sl()));
  sl.registerLazySingleton(
    () => ActivarModoColaboradorUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(
    () => CambiarDisponibilidadUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(
    () => RegistrarComercioUseCase(auth: sl(), comercios: sl()),
  );
  sl.registerLazySingleton(
    () => GetMiComercioUseCase(auth: sl(), comercios: sl()),
  );
  sl.registerLazySingleton(
    () => GetSolicitudesPendientesUseCase(solicitudes: sl()),
  );
  sl.registerLazySingleton(
    () =>
        DecidirSolicitudUseCase(auth: sl(), profiles: sl(), solicitudes: sl()),
  );
  sl.registerLazySingleton(
    () => GetNotificacionesNoLeidasUseCase(auth: sl(), notificaciones: sl()),
  );
  sl.registerLazySingleton(
    () => MarcarNotificacionesLeidasUseCase(notificaciones: sl()),
  );

  // HU-10: catálogo del comercio. Todos parten de GetComercioAprobadoUseCase.
  sl.registerLazySingleton(
    () => GetComercioAprobadoUseCase(auth: sl(), comercios: sl()),
  );
  sl.registerLazySingleton(
    () => GetProductosUseCase(comercioAprobado: sl(), catalogo: sl()),
  );
  sl.registerLazySingleton(() => GetCategoriasUseCase(catalogo: sl()));
  sl.registerLazySingleton(
    () => CrearProductoUseCase(comercioAprobado: sl(), catalogo: sl()),
  );
  sl.registerLazySingleton(
    () => EditarProductoUseCase(comercioAprobado: sl(), catalogo: sl()),
  );
  sl.registerLazySingleton(
    () => EliminarProductoUseCase(comercioAprobado: sl(), catalogo: sl()),
  );
  sl.registerLazySingleton(() => ElegirArchivoCsvUseCase(selector: sl()));
  sl.registerLazySingleton(
    () => CargarProductosCsvUseCase(comercioAprobado: sl(), catalogo: sl()),
  );

  // HU-14: ubicación del comercio y reporte de precios del colaborador.
  sl.registerLazySingleton(() => ObtenerUbicacionUseCase(servicio: sl()));
  sl.registerLazySingleton(
    () => FijarUbicacionComercioUseCase(
      auth: sl(),
      comercios: sl(),
      ubicacion: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GetColaboradorActivoUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(
    () => GetEstablecimientosCercanosUseCase(colaborador: sl(), reportes: sl()),
  );
  sl.registerLazySingleton(
    () => BuscarProductosUseCase(colaborador: sl(), reportes: sl()),
  );
  sl.registerLazySingleton(
    () => GetMisReportesUseCase(colaborador: sl(), reportes: sl()),
  );
  sl.registerLazySingleton(() => TomarFotoUseCase(selector: sl()));
  sl.registerLazySingleton(
    () => EnviarReportePrecioUseCase(
      colaborador: sl(),
      reportes: sl(),
      ubicacion: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => SugerirEstablecimientoUseCase(
      colaborador: sl(),
      reportes: sl(),
      ubicacion: sl(),
    ),
  );

  // ── Blocs: uno nuevo por pantalla (factory), porque guardan estado ──
  sl.registerFactory(() => LoginBloc(signIn: sl()));
  sl.registerFactory(() => RegisterBloc(signUp: sl()));
  sl.registerFactory(() => SessionBloc(getMyProfile: sl(), signOut: sl()));
  sl.registerFactory(() => ColaboradorOnboardingBloc(activar: sl()));
  sl.registerFactory(
    () => ComercioBloc(
      getMine: sl(),
      registrar: sl(),
      fijarUbicacion: sl(),
      obtenerUbicacion: sl(),
    ),
  );
  sl.registerFactory(
    () => NotificacionesBloc(noLeidas: sl(), marcarLeidas: sl()),
  );

  // HU-10: la lista del catálogo y la carga por archivo no necesitan datos.
  sl.registerFactory(() => CargaCsvBloc(elegir: sl(), cargar: sl()));
  sl.registerFactory<PaginatedBloc<Producto>>(() {
    final getProductos = sl<GetProductosUseCase>();
    // El aviso "tu comercio está pendiente de aprobación" debe llegar a la
    // pantalla, no un error genérico.
    return PaginatedBloc<Producto>(
      fetchPage: getProductos.call,
      errorMessageFor: mensajeDeFallo,
    );
  });

  // HU-14: el reporte de precio y la ubicación no necesitan datos.
  sl.registerFactory(() => UbicacionBloc(obtener: sl()));
  sl.registerFactory(() => ReporteFormBloc(tomarFoto: sl(), enviar: sl()));
  sl.registerFactory(() => SugerenciaBloc(sugerir: sl()));

  // HU-14: las listas reciben el dato de la pantalla (la ubicación, o el
  // establecimiento y la consulta). `PaginatedBloc<Producto>` ya está
  // registrado sin parámetros por el catálogo (HU-10), así que esta versión
  // lleva nombre: `sl<PaginatedBloc<Producto>>(instanceName: ..., param1: ...)`.
  sl.registerFactoryParam<PaginatedBloc<EstablecimientoCercano>, Ubicacion, void>(
    (ubicacion, _) {
      final cercanos = sl<GetEstablecimientosCercanosUseCase>();
      return PaginatedBloc<EstablecimientoCercano>(
        fetchPage: (request) => cercanos(ubicacion, request),
        errorMessageFor: mensajeDeFallo,
      );
    },
  );
  // El historial de reportes: el Home pide pocos y la pantalla completa una
  // página (`param1` es el tamaño de página).
  sl.registerFactoryParam<PaginatedBloc<MiReporte>, int, void>((pageSize, _) {
    final misReportes = sl<GetMisReportesUseCase>();
    return PaginatedBloc<MiReporte>(
      fetchPage: misReportes.call,
      pageSize: pageSize,
      errorMessageFor: mensajeDeFallo,
    );
  });
  sl.registerFactoryParam<PaginatedBloc<Producto>, String, ConsultaProducto>(
    (idComercio, consulta) {
      final buscar = sl<BuscarProductosUseCase>();
      return PaginatedBloc<Producto>(
        fetchPage: (request) => buscar(idComercio, consulta, request),
        errorMessageFor: mensajeDeFallo,
      );
    },
    instanceName: InstanciasSl.busquedaProductos,
  );

  // HU-10: el formulario recibe el producto que se edita (`null` al crear):
  // `sl<ProductoFormBloc>(param1: producto)`.
  sl.registerFactoryParam<ProductoFormBloc, Producto?, void>(
    (producto, _) => ProductoFormBloc(
      editando: producto,
      categorias: sl(),
      crear: sl(),
      editar: sl(),
      eliminar: sl(),
    ),
  );

  // HU-24: estos Bloc necesitan un dato de la pantalla, así que se piden
  // con `param1`: `sl<DecisionSolicitudBloc>(param1: solicitud)`.
  sl.registerFactoryParam<DecisionSolicitudBloc, Solicitud, void>(
    (solicitud, _) =>
        DecisionSolicitudBloc(solicitud: solicitud, decidir: sl()),
  );
  sl.registerFactoryParam<PaginatedBloc<Solicitud>, TipoSolicitud, void>(
    (tipo, _) {
      final getPendientes = sl<GetSolicitudesPendientesUseCase>();
      return PaginatedBloc<Solicitud>(
        fetchPage: (request) => getPendientes(tipo, request),
      );
    },
  );
}
