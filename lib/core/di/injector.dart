import 'package:get_it/get_it.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/estadisticas/data/repository/estadisticas_repository_impl.dart';
import 'package:smartcart/features/estadisticas/data/source/supabase_estadisticas_data_source.dart';
import 'package:smartcart/features/estadisticas/domain/repository/estadisticas_repository.dart';
import 'package:smartcart/features/estadisticas/domain/usecases/get_estadisticas_usecase.dart';
import 'package:smartcart/features/estadisticas/presentation/bloc/estadisticas_bloc.dart';
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
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';
import 'package:smartcart/features/busqueda/data/repository/busqueda_repository_impl.dart';
import 'package:smartcart/features/busqueda/data/source/supabase_busqueda_data_source.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/repository/busqueda_repository.dart';
import 'package:smartcart/features/busqueda/domain/usecases/buscar_productos_usecase.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/busqueda_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/catalog/data/repository/catalogo_repository_impl.dart';
import 'package:smartcart/features/confianza/data/repository/reporte_incorrecto_repository_impl.dart';
import 'package:smartcart/features/confianza/data/source/supabase_reporte_incorrecto_data_source.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';
import 'package:smartcart/features/confianza/domain/usecases/reportar_precio_incorrecto_usecase.dart';
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
import 'package:smartcart/features/comercio/domain/usecases/fijar_ubicacion_comercio_usecase.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/puntos/data/repository/puntos_repository_impl.dart';
import 'package:smartcart/features/puntos/data/source/supabase_puntos_data_source.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/repository/puntos_repository.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_movimientos_puntos_usecase.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_resumen_puntos_usecase.dart';
import 'package:smartcart/features/puntos/presentation/bloc/resumen_puntos_bloc.dart';
import 'package:smartcart/features/reportes/data/repository/reportes_repository_impl.dart';
import 'package:smartcart/features/reportes/data/repository/validacion_repository_impl.dart';
import 'package:smartcart/features/reportes/data/source/supabase_validacion_data_source.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/repository/validacion_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/validacion_usecases.dart';
import 'package:smartcart/features/reportes/presentation/bloc/accion_reporte_bloc.dart';
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
import 'package:smartcart/features/comparacion/data/repository/comparacion_repository_impl.dart';
import 'package:smartcart/features/comparacion/data/source/supabase_comparacion_data_source.dart';
import 'package:smartcart/features/comparacion/domain/repository/comparacion_repository.dart';
import 'package:smartcart/features/comparacion/domain/usecases/comparacion_usecases.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';
import 'package:smartcart/features/ubicacion/data/repository/ubicacion_cliente_repository_impl.dart';
import 'package:smartcart/features/ubicacion/data/source/geocoding_geocodificador.dart';
import 'package:smartcart/features/ubicacion/data/source/geolocator_servicio_ubicacion.dart';
import 'package:smartcart/features/ubicacion/data/source/supabase_ubicacion_cliente_data_source.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/geocodificador.dart';
import 'package:smartcart/features/ubicacion/domain/repository/servicio_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/ubicacion_cliente_repository.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import 'package:smartcart/features/cart/data/repository/carrito_repository_impl.dart';
import 'package:smartcart/features/cart/data/source/supabase_carrito_data_source.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cart/domain/usecases/agregar_al_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/cambiar_cantidad_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/get_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/quitar_del_carrito_usecase.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/calificaciones/data/repository/calificaciones_repository_impl.dart';
import 'package:smartcart/features/calificaciones/data/source/supabase_calificaciones_data_source.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/domain/repository/calificaciones_repository.dart';
import 'package:smartcart/features/calificaciones/domain/usecases/calificar_orden_usecase.dart';
import 'package:smartcart/features/calificaciones/presentation/bloc/calificar_orden_bloc.dart';
import 'package:smartcart/features/orders/data/repository/compras_repository_impl.dart';
import 'package:smartcart/features/orders/data/source/supabase_compras_data_source.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/repository/compras_repository.dart';
import 'package:smartcart/features/orders/domain/usecases/compras_usecases.dart';
import 'package:smartcart/features/orders/presentation/bloc/confirmar_compra_bloc.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/explorar/data/repository/explorar_repository_impl.dart';
import 'package:smartcart/features/explorar/data/source/supabase_explorar_data_source.dart';
import 'package:smartcart/features/explorar/domain/repository/explorar_repository.dart';
import 'package:smartcart/features/explorar/domain/usecases/explorar_usecases.dart';
import 'package:smartcart/features/favoritos/data/repository/favoritos_repository_impl.dart';
import 'package:smartcart/features/favoritos/data/source/supabase_favoritos_data_source.dart';
import 'package:smartcart/features/favoritos/domain/repository/favoritos_repository.dart';
import 'package:smartcart/features/favoritos/domain/usecases/favoritos_usecases.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';
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

  /// HU-17: `PaginatedBloc<ProductoConComercio>` se usa para la exploración y
  /// para los favoritos, y `PaginatedBloc<ComercioResumen>` también: cada uso
  /// lleva su nombre.
  static const explorarProductos = 'explorar-productos';
  static const explorarComercios = 'explorar-comercios';
  static const favoritosProductos = 'favoritos-productos';
  static const favoritosComercios = 'favoritos-comercios';
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
  // HU-15 y HU-16: confirmar reportes dudosos y puntos del colaborador.
  sl.registerLazySingleton<SupabaseValidacionDataSource>(
    () => SupabaseValidacionDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabasePuntosDataSource>(
    () => SupabasePuntosDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseCarritoDataSource>(
    () => SupabaseCarritoDataSource(client: sl()),
  );
  // HU-20 y HU-25: compras, órdenes y calificaciones.
  sl.registerLazySingleton<SupabaseComprasDataSource>(
    () => SupabaseComprasDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseCalificacionesDataSource>(
    () => SupabaseCalificacionesDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseFavoritosDataSource>(
    () => SupabaseFavoritosDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseExplorarDataSource>(
    () => SupabaseExplorarDataSource(client: sl()),
  );
  // HU-14: el GPS y la cámara se registran con el tipo del contrato; solo
  // estas líneas conocen `geolocator`, `image_picker` y `permission_handler`.
  sl.registerLazySingleton<ServicioUbicacion>(() => GeolocatorServicioUbicacion());
  sl.registerLazySingleton<SelectorFoto>(() => ImagePickerSelectorFoto());
  // HU-11: la foto del producto; también es la única línea que conoce
  // `file_picker` para esta tarea.
  sl.registerLazySingleton<SelectorImagen>(() => FilePickerSelectorImagen());
  sl.registerLazySingleton<SupabasePreciosDataSource>(
    () => SupabasePreciosDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseBusquedaDataSource>(
    () => SupabaseBusquedaDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseReporteIncorrectoDataSource>(
    () => SupabaseReporteIncorrectoDataSource(client: sl()),
  );
  // HU-19: ubicación del cliente. El geocodificador se registra con el tipo
  // del contrato; solo esta línea conoce el paquete `geocoding`.
  sl.registerLazySingleton<SupabaseUbicacionClienteDataSource>(
    () => SupabaseUbicacionClienteDataSource(client: sl()),
  );
  sl.registerLazySingleton<Geocodificador>(() => GeocodingGeocodificador());
  // HU-18: ofertas del carrito para compararlo.
  sl.registerLazySingleton<SupabaseComparacionDataSource>(
    () => SupabaseComparacionDataSource(client: sl()),
  );
  // HU-28: estadísticas del panel del administrador.
  sl.registerLazySingleton<SupabaseEstadisticasDataSource>(
    () => SupabaseEstadisticasDataSource(client: sl()),
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
  // HU-17: carrito, favoritos y exploración del cliente.
  sl.registerLazySingleton<CarritoRepository>(
    () => CarritoRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ComprasRepository>(
    () => ComprasRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<CalificacionesRepository>(
    () => CalificacionesRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<FavoritosRepository>(
    () => FavoritosRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ExplorarRepository>(
    () => ExplorarRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ReportesRepository>(
    () => ReportesRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ValidacionRepository>(
    () => ValidacionRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<PuntosRepository>(
    () => PuntosRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<PreciosRepository>(
    () => PreciosRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<BusquedaRepository>(
    () => BusquedaRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ReporteIncorrectoRepository>(
    () => ReporteIncorrectoRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<UbicacionClienteRepository>(
    () => UbicacionClienteRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ComparacionRepository>(
    () => ComparacionRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<EstadisticasRepository>(
    () => EstadisticasRepositoryImpl(dataSource: sl()),
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
    () => BuscarProductosReporteUseCase(colaborador: sl(), reportes: sl()),
  );
  sl.registerLazySingleton(
    () => GetMisReportesUseCase(colaborador: sl(), reportes: sl()),
  );

  // HU-15: confirmar o corregir reportes dudosos (colaborador y comercio).
  sl.registerLazySingleton(
    () => GetReportesPorConfirmarUseCase(colaborador: sl(), validacion: sl()),
  );
  sl.registerLazySingleton(
    () => ConfirmarReporteColaboradorUseCase(
      colaborador: sl(),
      ubicacion: sl(),
      validacion: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GetReportesDeMiComercioUseCase(comercio: sl(), validacion: sl()),
  );
  sl.registerLazySingleton(
    () => ConfirmarReporteComercioUseCase(comercio: sl(), validacion: sl()),
  );
  sl.registerLazySingleton(
    () => CorregirReporteComercioUseCase(comercio: sl(), validacion: sl()),
  );

  // HU-16: puntos, nivel, reputación e historial.
  sl.registerLazySingleton(
    () => GetResumenPuntosUseCase(colaborador: sl(), puntos: sl()),
  );
  sl.registerLazySingleton(
    () => GetMovimientosPuntosUseCase(colaborador: sl(), puntos: sl()),
  );

  // HU-17: todos parten de GetClienteActivoUseCase.
  sl.registerLazySingleton(
    () => GetClienteActivoUseCase(auth: sl(), profiles: sl()),
  );
  // HU-19: ubicación y radio del cliente.
  sl.registerLazySingleton(
    () => GetMiUbicacionUseCase(cliente: sl(), repositorio: sl()),
  );
  sl.registerLazySingleton(
    () => GuardarMiUbicacionUseCase(cliente: sl(), repositorio: sl()),
  );
  sl.registerLazySingleton(
    () => GetComerciosEnRadioUseCase(cliente: sl(), repositorio: sl()),
  );
  sl.registerLazySingleton(
    () => BuscarDireccionUseCase(geocodificador: sl()),
  );
  // HU-18: comparación del carrito.
  sl.registerLazySingleton(
    () => GetOfertasCarritoUseCase(cliente: sl(), repositorio: sl()),
  );
  sl.registerLazySingleton(() => CompararCarritoUseCase());
  sl.registerLazySingleton(
    () => GetEstadisticasUseCase(auth: sl(), profiles: sl(), estadisticas: sl()),
  );
  sl.registerLazySingleton(
    () => GetCarritoUseCase(cliente: sl(), carrito: sl()),
  );
  sl.registerLazySingleton(
    () => AgregarAlCarritoUseCase(cliente: sl(), carrito: sl()),
  );
  sl.registerLazySingleton(
    () => CambiarCantidadCarritoUseCase(cliente: sl(), carrito: sl()),
  );
  sl.registerLazySingleton(
    () => QuitarDelCarritoUseCase(cliente: sl(), carrito: sl()),
  );
  // HU-20: armar el plan con el carrito, confirmar y listar las órdenes.
  sl.registerLazySingleton(
    () => GetPlanCompraUseCase(carrito: sl(), compras: sl()),
  );
  sl.registerLazySingleton(
    () => ConfirmarCompraUseCase(
      cliente: sl(),
      compras: sl(),
      ubicacion: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GetMisOrdenesUseCase(cliente: sl(), compras: sl()),
  );
  // HU-25: calificar una orden completada.
  sl.registerLazySingleton(
    () => CalificarOrdenUseCase(cliente: sl(), calificaciones: sl()),
  );
  sl.registerLazySingleton(
    () => GetFavoritosIdsUseCase(cliente: sl(), favoritos: sl()),
  );
  sl.registerLazySingleton(
    () => GetFavoritosProductosUseCase(cliente: sl(), favoritos: sl()),
  );
  sl.registerLazySingleton(
    () => GetFavoritosComerciosUseCase(cliente: sl(), favoritos: sl()),
  );
  sl.registerLazySingleton(
    () => CambiarFavoritoUseCase(cliente: sl(), favoritos: sl()),
  );
  sl.registerLazySingleton(
    () => ExplorarProductosUseCase(cliente: sl(), explorar: sl()),
  );
  sl.registerLazySingleton(
    () => ExplorarComerciosUseCase(cliente: sl(), explorar: sl()),
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
  // HU-11: precios, disponibilidad y promociones. También parten del
  // comercio aprobado.
  sl.registerLazySingleton(
    () => GetFichaPrecioUseCase(comercioAprobado: sl(), precios: sl()),
  );
  sl.registerLazySingleton(
    () => ActualizarPrecioUseCase(comercioAprobado: sl(), precios: sl()),
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

  // HU-12: búsqueda del cliente.
  sl.registerLazySingleton(
    () => BuscarProductosUseCase(auth: sl(), busqueda: sl()),
  );
  sl.registerLazySingleton(
    () => GetDetalleProductoUseCase(auth: sl(), busqueda: sl()),
  );
  // HU-13: reportar un precio incorrecto desde el detalle.
  sl.registerLazySingleton(
    () => ReportarPrecioIncorrectoUseCase(cliente: sl(), reportes: sl()),
  );
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
  // HU-11: la lista del catálogo agrega búsqueda y filtro por categoría.
  sl.registerFactory<PaginatedBloc<Producto>>(
    () => CatalogoListaBloc(getProductos: sl<GetProductosUseCase>()),
  );
  sl.registerFactory(() => InventarioBloc(encabezado: sl()));

  // HU-14: el reporte de precio y la ubicación no necesitan datos.
  sl.registerFactory(() => UbicacionBloc(obtener: sl()));
  // HU-18: la comparación del carrito y los precios de la pantalla del
  // carrito.
  sl.registerFactory(
    () => ComparacionBloc(ofertas: sl(), miUbicacion: sl(), comparar: sl()),
  );
  sl.registerFactory(() => PreciosCarritoBloc(ofertas: sl()));
  // HU-28: el panel del administrador.
  sl.registerFactory(() => EstadisticasBloc(obtener: sl()));
  // HU-19: el mapa de comercios del cliente.
  sl.registerFactory(
    () => MapaComerciosBloc(
      miUbicacion: sl(),
      guardar: sl(),
      comercios: sl(),
      gps: sl(),
      buscarDireccion: sl(),
    ),
  );
  sl.registerFactory(() => ReporteFormBloc(tomarFoto: sl(), enviar: sl()));
  sl.registerFactory(() => SugerenciaBloc(sugerir: sl()));
  // HU-15 y HU-16.
  sl.registerFactory(
    () => AccionReporteBloc(
      confirmarColaborador: sl(),
      confirmarComercio: sl(),
      corregirComercio: sl(),
    ),
  );
  sl.registerFactory(() => ResumenPuntosBloc(getResumen: sl()));

  // HU-17: el carrito y los favoritos los crea el RolShell del cliente (uno
  // por sesión) y los comparten todas sus pantallas.
  sl.registerFactory(
    () => CarritoBloc(
      obtener: sl(),
      agregar: sl(),
      cambiarCantidad: sl(),
      quitar: sl(),
    ),
  );
  sl.registerFactory(() => FavoritosBloc(obtener: sl(), cambiar: sl()));

  // HU-20: confirmar la compra y la lista de órdenes del cliente.
  sl.registerFactory(
    () => ConfirmarCompraBloc(
      obtenerPlan: sl(),
      confirmar: sl(),
      ubicacion: sl(),
    ),
  );
  sl.registerFactory<PaginatedBloc<Orden>>(
    () => PaginatedBloc<Orden>(
      fetchPage: sl<GetMisOrdenesUseCase>().call,
      errorMessageFor: mensajeDeFallo,
    ),
  );
  // HU-25: la orden y a quién se califica llegan de la pantalla.
  sl.registerFactoryParam<CalificarOrdenBloc, String, TipoCalificacion>(
    (idOrden, tipo) => CalificarOrdenBloc(
      calificar: sl(),
      idOrden: idOrden,
      tipo: tipo,
    ),
  );

  // HU-17: listas paginadas de la exploración (con el texto buscado como
  // `param1`) y de los favoritos. Todas llevan nombre porque comparten tipo.
  sl.registerFactoryParam<PaginatedBloc<ProductoConComercio>, String, void>(
    (texto, _) {
      final explorar = sl<ExplorarProductosUseCase>();
      return PaginatedBloc<ProductoConComercio>(
        fetchPage: (request) => explorar(texto, request),
        errorMessageFor: mensajeDeFallo,
      );
    },
    instanceName: InstanciasSl.explorarProductos,
  );
  sl.registerFactoryParam<PaginatedBloc<ComercioResumen>, String, void>(
    (texto, _) {
      final explorar = sl<ExplorarComerciosUseCase>();
      return PaginatedBloc<ComercioResumen>(
        fetchPage: (request) => explorar(texto, request),
        errorMessageFor: mensajeDeFallo,
      );
    },
    instanceName: InstanciasSl.explorarComercios,
  );
  sl.registerFactory<PaginatedBloc<ProductoConComercio>>(
    () {
      final favoritos = sl<GetFavoritosProductosUseCase>();
      return PaginatedBloc<ProductoConComercio>(
        fetchPage: favoritos.call,
        errorMessageFor: mensajeDeFallo,
      );
    },
    instanceName: InstanciasSl.favoritosProductos,
  );
  sl.registerFactory<PaginatedBloc<ComercioResumen>>(
    () {
      final favoritos = sl<GetFavoritosComerciosUseCase>();
      return PaginatedBloc<ComercioResumen>(
        fetchPage: favoritos.call,
        errorMessageFor: mensajeDeFallo,
      );
    },
    instanceName: InstanciasSl.favoritosComercios,
  );

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
  // HU-15: los reportes por confirmar; `param1` dice si los pide el comercio
  // (los de sus productos) o un colaborador (los de otras personas).
  sl.registerFactoryParam<PaginatedBloc<ReportePorConfirmar>, bool, void>(
    (esComercio, _) {
      final fetch = esComercio
          ? sl<GetReportesDeMiComercioUseCase>().call
          : sl<GetReportesPorConfirmarUseCase>().call;
      return PaginatedBloc<ReportePorConfirmar>(
        fetchPage: fetch,
        errorMessageFor: mensajeDeFallo,
      );
    },
  );
  // HU-16: el historial de puntos del colaborador.
  sl.registerFactory<PaginatedBloc<MovimientoPuntos>>(
    () => PaginatedBloc<MovimientoPuntos>(
      fetchPage: sl<GetMovimientosPuntosUseCase>().call,
      errorMessageFor: mensajeDeFallo,
    ),
  );
  sl.registerFactoryParam<PaginatedBloc<Producto>, String, ConsultaProductoReporte>(
    (idComercio, consulta) {
      final buscar = sl<BuscarProductosReporteUseCase>();
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
      guardarPromocion: sl(),
      quitarPromocion: sl(),
    ),
  );

  // HU-12: la búsqueda arranca con el texto del Home y el detalle recibe qué
  // producto abrir: `sl<PaginatedBloc<ResultadoBusqueda>>(param1: texto)`.
  sl.registerFactoryParam<PaginatedBloc<ResultadoBusqueda>, String, void>(
    (texto, _) => BusquedaBloc(buscar: sl(), textoInicial: texto),
  );
  sl.registerFactoryParam<DetalleProductoBloc, ConsultaProducto, void>(
    (consulta, _) => DetalleProductoBloc(
      consulta: consulta,
      detalle: sl(),
      reportar: sl(),
    ),
  );

  // HU-08: la disponibilidad del repartidor arranca con el valor guardado en
  // su perfil: `sl<DisponibilidadBloc>(param1: perfil.courierAvailable)`.
  sl.registerFactoryParam<DisponibilidadBloc, bool, void>(
    (inicial, _) => DisponibilidadBloc(cambiar: sl(), inicial: inicial),
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
