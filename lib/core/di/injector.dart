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
import 'package:smartcart/features/catalog/data/source/file_picker_selector_imagen.dart';
import 'package:smartcart/features/catalog/data/source/supabase_catalogo_data_source.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_imagen.dart';
import 'package:smartcart/features/catalog/domain/usecases/cargar_productos_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_archivo_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_foto_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_categorias_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_encabezado_catalogo_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_formulario_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_productos_usecase.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/catalogo_lista_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/prices/data/repository/precios_repository_impl.dart';
import 'package:smartcart/features/prices/data/source/supabase_precios_data_source.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/usecases/actualizar_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/cambiar_disponibilidad_producto_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_producto_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_promocion_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/quitar_promocion_usecase.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/data/repository/comercio_repository_impl.dart';
import 'package:smartcart/features/comercio/data/source/supabase_comercio_data_source.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
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
  // HU-11: la foto del producto; también es la única línea que conoce
  // `file_picker` para esta tarea.
  sl.registerLazySingleton<SelectorImagen>(() => FilePickerSelectorImagen());
  sl.registerLazySingleton<SupabasePreciosDataSource>(
    () => SupabasePreciosDataSource(client: sl()),
  );

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
  sl.registerLazySingleton<PreciosRepository>(
    () => PreciosRepositoryImpl(dataSource: sl()),
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

  // HU-11: precios, disponibilidad y promociones. También parten del
  // comercio aprobado.
  sl.registerLazySingleton(
    () => GetFichaPrecioUseCase(comercioAprobado: sl(), precios: sl()),
  );
  sl.registerLazySingleton(
    () => ActualizarPrecioUseCase(comercioAprobado: sl(), precios: sl()),
  );
  sl.registerLazySingleton(
    () => CambiarDisponibilidadProductoUseCase(
        comercioAprobado: sl(), precios: sl()),
  );
  sl.registerLazySingleton(
    () => GuardarPromocionUseCase(comercioAprobado: sl(), precios: sl()),
  );
  sl.registerLazySingleton(
    () => QuitarPromocionUseCase(comercioAprobado: sl(), precios: sl()),
  );
  // HU-11: catálogo con el diseño nuevo (encabezado, formulario con foto y
  // "Guardar cambios" que guarda producto, foto y precio en un paso).
  sl.registerLazySingleton(
    () => GetEncabezadoCatalogoUseCase(
        comercioAprobado: sl(), categorias: sl(), catalogo: sl()),
  );
  sl.registerLazySingleton(
    () => GetFormularioProductoUseCase(comercioAprobado: sl(), categorias: sl()),
  );
  sl.registerLazySingleton(() => ElegirFotoProductoUseCase(selector: sl()));
  sl.registerLazySingleton(
    () => GuardarProductoUseCase(
      crear: sl(),
      editar: sl(),
      actualizarPrecio: sl(),
      comercioAprobado: sl(),
      catalogo: sl(),
    ),
  );

  // ── Blocs: uno nuevo por pantalla (factory), porque guardan estado ──
  sl.registerFactory(() => LoginBloc(signIn: sl()));
  sl.registerFactory(() => RegisterBloc(signUp: sl()));
  sl.registerFactory(() => SessionBloc(getMyProfile: sl(), signOut: sl()));
  sl.registerFactory(() => ColaboradorOnboardingBloc(activar: sl()));
  sl.registerFactory(() => ComercioBloc(getMine: sl(), registrar: sl()));
  sl.registerFactory(
    () => NotificacionesBloc(noLeidas: sl(), marcarLeidas: sl()),
  );

  // HU-10: la lista del catálogo y la carga por archivo no necesitan datos.
  sl.registerFactory(() => CargaCsvBloc(elegir: sl(), cargar: sl()));
  // HU-11: la lista del catálogo agrega búsqueda y filtro por categoría.
  sl.registerFactory<PaginatedBloc<Producto>>(
    () => CatalogoListaBloc(getProductos: sl<GetProductosUseCase>()),
  );
  sl.registerFactory(
    () => InventarioBloc(encabezado: sl(), disponibilidad: sl(), eliminar: sl()),
  );

  // HU-10: el formulario recibe el producto que se edita (`null` al crear):
  // `sl<ProductoFormBloc>(param1: producto)`.
  sl.registerFactoryParam<ProductoFormBloc, Producto?, void>(
    (producto, _) => ProductoFormBloc(
      editando: producto,
      formulario: sl(),
      guardar: sl(),
      eliminar: sl(),
      elegirFoto: sl(),
    ),
  );

  // HU-11: la edición rápida recibe el producto:
  // `sl<PrecioProductoBloc>(param1: producto)`.
  sl.registerFactoryParam<PrecioProductoBloc, Producto, void>(
    (producto, _) => PrecioProductoBloc(
      producto: producto,
      ficha: sl(),
      disponibilidad: sl(),
      guardarPromocion: sl(),
      quitarPromocion: sl(),
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
