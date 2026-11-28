import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/di/injector.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/catalog/data/repository/catalogo_repository_impl.dart';
import 'package:smartcart/features/confianza/data/repository/reporte_incorrecto_repository_impl.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';
import 'package:smartcart/features/confianza/domain/usecases/reportar_precio_incorrecto_usecase.dart';
import 'package:smartcart/features/catalog/data/source/file_picker_selector_csv.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';
import 'package:smartcart/features/catalog/domain/usecases/cargar_productos_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_productos_usecase.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/comercio/domain/usecases/fijar_ubicacion_comercio_usecase.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/reportes/data/repository/reportes_repository_impl.dart';
import 'package:smartcart/features/reportes/data/source/image_picker_selector_foto.dart';
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
import 'package:smartcart/features/cart/data/repository/carrito_repository_impl.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cart/domain/usecases/agregar_al_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/cambiar_cantidad_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/get_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/quitar_del_carrito_usecase.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/explorar/data/repository/explorar_repository_impl.dart';
import 'package:smartcart/features/explorar/domain/repository/explorar_repository.dart';
import 'package:smartcart/features/explorar/domain/usecases/explorar_usecases.dart';
import 'package:smartcart/features/calificaciones/data/repository/calificaciones_repository_impl.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/domain/repository/calificaciones_repository.dart';
import 'package:smartcart/features/calificaciones/domain/usecases/calificar_orden_usecase.dart';
import 'package:smartcart/features/calificaciones/presentation/bloc/calificar_orden_bloc.dart';
import 'package:smartcart/features/orders/data/repository/compras_repository_impl.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/repository/compras_repository.dart';
import 'package:smartcart/features/orders/domain/usecases/compras_usecases.dart';
import 'package:smartcart/features/orders/presentation/bloc/confirmar_compra_bloc.dart';
import 'package:smartcart/features/favoritos/data/repository/favoritos_repository_impl.dart';
import 'package:smartcart/features/favoritos/domain/repository/favoritos_repository.dart';
import 'package:smartcart/features/favoritos/domain/usecases/favoritos_usecases.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';
import 'package:smartcart/features/prices/data/repository/precios_repository_impl.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/usecases/actualizar_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_promocion_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/quitar_promocion_usecase.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_producto_usecase.dart';
import 'package:smartcart/features/catalog/data/source/file_picker_selector_imagen.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_imagen.dart';
import 'package:smartcart/features/catalog/presentation/bloc/catalogo_lista_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/busqueda/data/repository/busqueda_repository_impl.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/repository/busqueda_repository.dart';
import 'package:smartcart/features/busqueda/domain/usecases/buscar_productos_usecase.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/busqueda_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/puntos/data/repository/puntos_repository_impl.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/repository/puntos_repository.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_movimientos_puntos_usecase.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_resumen_puntos_usecase.dart';
import 'package:smartcart/features/puntos/presentation/bloc/resumen_puntos_bloc.dart';
import 'package:smartcart/features/reportes/data/repository/validacion_repository_impl.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/repository/validacion_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/validacion_usecases.dart';
import 'package:smartcart/features/reportes/presentation/bloc/accion_reporte_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartcart/features/comparacion/data/repository/comparacion_repository_impl.dart';
import 'package:smartcart/features/comparacion/domain/repository/comparacion_repository.dart';
import 'package:smartcart/features/comparacion/domain/usecases/comparacion_usecases.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';
import 'package:smartcart/features/ubicacion/data/repository/ubicacion_cliente_repository_impl.dart';
import 'package:smartcart/features/ubicacion/data/source/geocoding_geocodificador.dart';
import 'package:smartcart/features/ubicacion/domain/repository/geocodificador.dart';
import 'package:smartcart/features/ubicacion/domain/repository/ubicacion_cliente_repository.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/ubicacion_cliente_usecases.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';

void main() {
  tearDown(() => sl.reset());

  test('registra los repositorios con el tipo del contrato del dominio', () {
    setupDependencies();

    expect(sl.isRegistered<AuthRepository>(), isTrue);
    expect(sl.isRegistered<ProfileRepository>(), isTrue);
    expect(sl.isRegistered<ComercioRepository>(), isTrue);
    expect(sl.isRegistered<SignInUseCase>(), isTrue);
  });

  test('los Bloc se registran como fábrica: cada pantalla recibe uno nuevo', () {
    setupDependencies();

    expect(sl.isRegistered<LoginBloc>(), isTrue);
    expect(sl.isRegistered<RegisterBloc>(), isTrue);
    expect(sl.isRegistered<SessionBloc>(), isTrue);
    expect(sl.isRegistered<ColaboradorOnboardingBloc>(), isTrue);
    expect(sl.isRegistered<ComercioBloc>(), isTrue);
    expect(sl.isRegistered<NotificacionesBloc>(), isTrue);
    expect(sl.isRegistered<DecisionSolicitudBloc>(), isTrue);
    expect(sl.isRegistered<PaginatedBloc<Solicitud>>(), isTrue);
  });

  test('HU-24: repositorios y caso de uso de aprobación registrados', () {
    setupDependencies();

    expect(sl.isRegistered<SolicitudesRepository>(), isTrue);
    expect(sl.isRegistered<NotificacionRepository>(), isTrue);
    expect(sl.isRegistered<DecidirSolicitudUseCase>(), isTrue);
  });

  test('HU-10: el catálogo se registra con los tipos del contrato', () {
    setupDependencies();

    expect(sl.isRegistered<CatalogoRepository>(), isTrue);
    expect(sl.isRegistered<SelectorArchivoCsv>(), isTrue);
    expect(sl.isRegistered<GetComercioAprobadoUseCase>(), isTrue);
    expect(sl.isRegistered<GetProductosUseCase>(), isTrue);
    expect(sl.isRegistered<CrearProductoUseCase>(), isTrue);
    expect(sl.isRegistered<EditarProductoUseCase>(), isTrue);
    expect(sl.isRegistered<EliminarProductoUseCase>(), isTrue);
    expect(sl.isRegistered<CargarProductosCsvUseCase>(), isTrue);
    expect(sl.isRegistered<ProductoFormBloc>(), isTrue);
    expect(sl.isRegistered<CargaCsvBloc>(), isTrue);
    expect(sl.isRegistered<PaginatedBloc<Producto>>(), isTrue);
  });

  group('HU-10: el localizador arma la cadena completa del catálogo', () {
    // Un cliente de Supabase sin conexión: basta para construir las
    // dependencias, porque ninguna llama a la red al crearse.
    setUp(() {
      setupDependencies();
      sl.unregister<SupabaseClient>();
      sl.registerLazySingleton<SupabaseClient>(
        () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
      );
    });

    test('los Bloc son fábricas: cada pantalla recibe uno nuevo', () {
      expect(identical(sl<CargaCsvBloc>(), sl<CargaCsvBloc>()), isFalse);
      expect(
        identical(sl<PaginatedBloc<Producto>>(), sl<PaginatedBloc<Producto>>()),
        isFalse,
      );
    });

    test('los casos de uso son únicos y comparten el repositorio', () {
      expect(
        identical(sl<CrearProductoUseCase>(), sl<CrearProductoUseCase>()),
        isTrue,
      );
      expect(sl<CatalogoRepository>(), isA<CatalogoRepositoryImpl>());
      expect(sl<SelectorArchivoCsv>(), isA<FilePickerSelectorCsv>());
    });

    test('el formulario acepta un producto para editar y null para crear', () {
      const producto = Producto(
        id: 'p1',
        nombre: 'Arroz blanco',
        idCategoria: 'cat-super',
        categoria: 'Super',
      );

      expect(sl<ProductoFormBloc>(param1: producto).editando, producto);
      expect(sl<ProductoFormBloc>(param1: null).editando, isNull);
    });
  });

  test('HU-14: la ubicación y los reportes se registran con el tipo del contrato',
      () {
    setupDependencies();

    expect(sl.isRegistered<ServicioUbicacion>(), isTrue);
    expect(sl.isRegistered<SelectorFoto>(), isTrue);
    expect(sl.isRegistered<ReportesRepository>(), isTrue);
    expect(sl.isRegistered<ObtenerUbicacionUseCase>(), isTrue);
    expect(sl.isRegistered<FijarUbicacionComercioUseCase>(), isTrue);
    expect(sl.isRegistered<GetColaboradorActivoUseCase>(), isTrue);
    expect(sl.isRegistered<GetEstablecimientosCercanosUseCase>(), isTrue);
    expect(sl.isRegistered<BuscarProductosReporteUseCase>(), isTrue);
    expect(sl.isRegistered<GetMisReportesUseCase>(), isTrue);
    expect(sl.isRegistered<PaginatedBloc<MiReporte>>(), isTrue);
    expect(sl.isRegistered<TomarFotoUseCase>(), isTrue);
    expect(sl.isRegistered<EnviarReportePrecioUseCase>(), isTrue);
    expect(sl.isRegistered<SugerirEstablecimientoUseCase>(), isTrue);
    expect(sl.isRegistered<UbicacionBloc>(), isTrue);
    expect(sl.isRegistered<ReporteFormBloc>(), isTrue);
    expect(sl.isRegistered<SugerenciaBloc>(), isTrue);
    expect(sl.isRegistered<PaginatedBloc<EstablecimientoCercano>>(), isTrue);
    // PaginatedBloc<Producto> existe dos veces: sin nombre (catálogo, HU-10)
    // y con nombre (búsqueda del reporte, HU-14).
    expect(sl.isRegistered<PaginatedBloc<Producto>>(), isTrue);
    expect(
      sl.isRegistered<PaginatedBloc<Producto>>(
        instanceName: InstanciasSl.busquedaProductos,
      ),
      isTrue,
    );
  });

  group('HU-14: el localizador arma la cadena completa del reporte', () {
    setUp(() {
      setupDependencies();
      sl.unregister<SupabaseClient>();
      sl.registerLazySingleton<SupabaseClient>(
        () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
      );
    });

    test('el GPS y la cámara son las implementaciones reales de los contratos',
        () {
      expect(sl<ServicioUbicacion>(), isA<GeolocatorServicioUbicacion>());
      expect(sl<SelectorFoto>(), isA<ImagePickerSelectorFoto>());
      expect(sl<ReportesRepository>(), isA<ReportesRepositoryImpl>());
    });

    test('las listas reciben su dato de la pantalla (param1 y param2)', () {
      const ubicacion = Ubicacion(latitud: 3.45, longitud: -76.53);

      expect(
        sl<PaginatedBloc<EstablecimientoCercano>>(param1: ubicacion),
        isA<PaginatedBloc<EstablecimientoCercano>>(),
      );
      expect(
        sl<PaginatedBloc<Producto>>(
          instanceName: InstanciasSl.busquedaProductos,
          param1: 'c1',
          param2: const ConsultaProductoReporte(texto: 'arroz'),
        ),
        isA<PaginatedBloc<Producto>>(),
      );
    });

    test('el historial de reportes recibe el tamaño de página (param1)', () {
      final home = sl<PaginatedBloc<MiReporte>>(param1: 3);
      final pantalla = sl<PaginatedBloc<MiReporte>>(param1: 20);

      expect(home.pageSize, 3);
      expect(pantalla.pageSize, 20);
      expect(identical(home, pantalla), isFalse);
    });

    test('el catálogo sigue pudiendo pedir su lista sin parámetros', () {
      expect(sl<PaginatedBloc<Producto>>(), isA<PaginatedBloc<Producto>>());
    });

    test('los Bloc de los reportes son fábricas', () {
      expect(identical(sl<UbicacionBloc>(), sl<UbicacionBloc>()), isFalse);
      expect(identical(sl<ReporteFormBloc>(), sl<ReporteFormBloc>()), isFalse);
      expect(identical(sl<SugerenciaBloc>(), sl<SugerenciaBloc>()), isFalse);
      expect(identical(sl<ComercioBloc>(), sl<ComercioBloc>()), isFalse);
    });

    test('los casos de uso son únicos', () {
      expect(
        identical(
            sl<EnviarReportePrecioUseCase>(), sl<EnviarReportePrecioUseCase>()),
        isTrue,
      );
    });
  });

  test('HU-17: el carrito, los favoritos y la exploración se registran con '
      'el tipo del contrato', () {
    setupDependencies();

    expect(sl.isRegistered<CarritoRepository>(), isTrue);
    expect(sl.isRegistered<FavoritosRepository>(), isTrue);
    expect(sl.isRegistered<ExplorarRepository>(), isTrue);
    expect(sl.isRegistered<GetClienteActivoUseCase>(), isTrue);
    expect(sl.isRegistered<GetCarritoUseCase>(), isTrue);
    expect(sl.isRegistered<AgregarAlCarritoUseCase>(), isTrue);
    expect(sl.isRegistered<CambiarCantidadCarritoUseCase>(), isTrue);
    expect(sl.isRegistered<QuitarDelCarritoUseCase>(), isTrue);
    expect(sl.isRegistered<GetFavoritosIdsUseCase>(), isTrue);
    expect(sl.isRegistered<GetFavoritosProductosUseCase>(), isTrue);
    expect(sl.isRegistered<GetFavoritosComerciosUseCase>(), isTrue);
    expect(sl.isRegistered<CambiarFavoritoUseCase>(), isTrue);
    expect(sl.isRegistered<ExplorarProductosUseCase>(), isTrue);
    expect(sl.isRegistered<ExplorarComerciosUseCase>(), isTrue);
    expect(sl.isRegistered<CarritoBloc>(), isTrue);
    expect(sl.isRegistered<FavoritosBloc>(), isTrue);
    // Las listas comparten tipo con otras, así que llevan nombre.
    for (final nombre in [
      InstanciasSl.explorarProductos,
      InstanciasSl.favoritosProductos,
    ]) {
      expect(
        sl.isRegistered<PaginatedBloc<ProductoConComercio>>(instanceName: nombre),
        isTrue,
        reason: nombre,
      );
    }
    for (final nombre in [
      InstanciasSl.explorarComercios,
      InstanciasSl.favoritosComercios,
    ]) {
      expect(
        sl.isRegistered<PaginatedBloc<ComercioResumen>>(instanceName: nombre),
        isTrue,
        reason: nombre,
      );
    }
  });

  test('HU-20 y HU-25: compras, órdenes y calificaciones se registran con '
      'el tipo del contrato', () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );

    expect(sl<ComprasRepository>(), isA<ComprasRepositoryImpl>());
    expect(
        sl<CalificacionesRepository>(), isA<CalificacionesRepositoryImpl>());
    expect(sl.isRegistered<GetPlanCompraUseCase>(), isTrue);
    expect(sl.isRegistered<ConfirmarCompraUseCase>(), isTrue);
    expect(sl.isRegistered<GetMisOrdenesUseCase>(), isTrue);
    expect(sl.isRegistered<CalificarOrdenUseCase>(), isTrue);
    // Los Blocs son fábricas: cada pantalla recibe uno nuevo.
    expect(identical(sl<ConfirmarCompraBloc>(), sl<ConfirmarCompraBloc>()),
        isFalse);
    expect(
        identical(
            sl<PaginatedBloc<Orden>>(), sl<PaginatedBloc<Orden>>()),
        isFalse);
    final calificar = sl<CalificarOrdenBloc>(
        param1: 'o1', param2: TipoCalificacion.repartidor);
    expect(calificar.idOrden, 'o1');
    expect(calificar.tipo, TipoCalificacion.repartidor);
  });

  group('HU-17: el localizador arma la cadena completa del cliente', () {
    setUp(() {
      setupDependencies();
      sl.unregister<SupabaseClient>();
      sl.registerLazySingleton<SupabaseClient>(
        () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
      );
    });

    test('las implementaciones reales cumplen los contratos', () {
      expect(sl<CarritoRepository>(), isA<CarritoRepositoryImpl>());
      expect(sl<FavoritosRepository>(), isA<FavoritosRepositoryImpl>());
      expect(sl<ExplorarRepository>(), isA<ExplorarRepositoryImpl>());
    });

    test('el carrito y los favoritos son fábricas: uno por sesión', () {
      expect(identical(sl<CarritoBloc>(), sl<CarritoBloc>()), isFalse);
      expect(identical(sl<FavoritosBloc>(), sl<FavoritosBloc>()), isFalse);
    });

    test('los casos de uso son únicos y comparten el repositorio', () {
      expect(
        identical(sl<AgregarAlCarritoUseCase>(), sl<AgregarAlCarritoUseCase>()),
        isTrue,
      );
      expect(
        identical(sl<GetClienteActivoUseCase>(), sl<GetClienteActivoUseCase>()),
        isTrue,
      );
    });

    test('las listas de exploración reciben el texto buscado (param1)', () {
      final productos = sl<PaginatedBloc<ProductoConComercio>>(
        instanceName: InstanciasSl.explorarProductos,
        param1: 'arroz',
      );
      final comercios = sl<PaginatedBloc<ComercioResumen>>(
        instanceName: InstanciasSl.explorarComercios,
        param1: 'cali',
      );

      expect(productos, isA<PaginatedBloc<ProductoConComercio>>());
      expect(comercios, isA<PaginatedBloc<ComercioResumen>>());
    });

    test('las listas de favoritos no necesitan parámetros', () {
      expect(
        sl<PaginatedBloc<ProductoConComercio>>(
          instanceName: InstanciasSl.favoritosProductos,
        ),
        isA<PaginatedBloc<ProductoConComercio>>(),
      );
      expect(
        sl<PaginatedBloc<ComercioResumen>>(
          instanceName: InstanciasSl.favoritosComercios,
        ),
        isA<PaginatedBloc<ComercioResumen>>(),
      );
    });
  });

  test('HU-11: precios y promociones se registran con el tipo del contrato',
      () {
    setupDependencies();

    expect(sl.isRegistered<PreciosRepository>(), isTrue);
    expect(sl.isRegistered<GetFichaPrecioUseCase>(), isTrue);
    expect(sl.isRegistered<ActualizarPrecioUseCase>(), isTrue);
    expect(sl.isRegistered<GuardarPromocionUseCase>(), isTrue);
    expect(sl.isRegistered<QuitarPromocionUseCase>(), isTrue);
    expect(sl.isRegistered<PrecioProductoBloc>(), isTrue);
    expect(sl.isRegistered<GuardarProductoUseCase>(), isTrue);
    expect(sl.isRegistered<SelectorImagen>(), isTrue);
    expect(sl.isRegistered<InventarioBloc>(), isTrue);
  });

  test('HU-11: el Bloc de precios recibe el producto y usa el repositorio real',
      () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );
    const producto = Producto(
      id: 'p1',
      nombre: 'Arroz blanco',
      idCategoria: 'cat-super',
      categoria: 'Super',
    );

    final bloc = sl<PrecioProductoBloc>(param1: producto);

    expect(bloc.producto, producto);
    expect(identical(bloc, sl<PrecioProductoBloc>(param1: producto)), isFalse);
    expect(sl<PreciosRepository>(), isA<PreciosRepositoryImpl>());
    expect(sl<SelectorImagen>(), isA<FilePickerSelectorImagen>());
    // La lista del catálogo agrega búsqueda y filtro por categoría.
    expect(sl<PaginatedBloc<Producto>>(), isA<CatalogoListaBloc>());
    expect(sl<InventarioBloc>(), isNot(same(sl<InventarioBloc>())));
    expect(sl<GuardarProductoUseCase>(), same(sl<GuardarProductoUseCase>()));
  });

  test('HU-12: la búsqueda se registra con los tipos del contrato', () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );

    expect(sl<BusquedaRepository>(), isA<BusquedaRepositoryImpl>());
    expect(sl<BuscarProductosUseCase>(), same(sl<BuscarProductosUseCase>()));
    expect(sl.isRegistered<GetDetalleProductoUseCase>(), isTrue);

    final busqueda = sl<PaginatedBloc<ResultadoBusqueda>>(param1: 'arroz');
    expect(busqueda, isA<BusquedaBloc>());
    expect((busqueda as BusquedaBloc).texto, 'arroz');

    const consulta = ConsultaPorCodigo('7701234567890');
    expect(sl<DetalleProductoBloc>(param1: consulta).consulta, consulta);
  });

  test('HU-13: el reporte de precio incorrecto se registra con el tipo del '
      'contrato', () {
    setupDependencies();

    expect(sl.isRegistered<ReporteIncorrectoRepository>(), isTrue);
    expect(sl.isRegistered<ReportarPrecioIncorrectoUseCase>(), isTrue);
  });

  test('HU-08: la disponibilidad del repartidor se pide al localizador con '
      'el valor guardado (param1)', () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );

    final disponible = sl<DisponibilidadBloc>(param1: true);
    final noDisponible = sl<DisponibilidadBloc>(param1: false);

    expect(disponible.state.disponible, isTrue);
    expect(noDisponible.state.disponible, isFalse);
    // Cada pantalla tiene su propio Bloc: es una fábrica.
    expect(identical(disponible, sl<DisponibilidadBloc>(param1: true)), isFalse);
  });

  test('HU-13: el detalle arma el reporte con el repositorio real', () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );
    const consulta = ConsultaPorClave('cb:7701234567890');

    expect(sl<ReporteIncorrectoRepository>(),
        isA<ReporteIncorrectoRepositoryImpl>());
    expect(sl<ReportarPrecioIncorrectoUseCase>(),
        same(sl<ReportarPrecioIncorrectoUseCase>()));

    final bloc = sl<DetalleProductoBloc>(param1: consulta);
    expect(bloc.consulta, consulta);
    expect(bloc.state.reportando, isEmpty);
    // Cada pantalla de detalle tiene su propio Bloc.
    expect(identical(bloc, sl<DetalleProductoBloc>(param1: consulta)), isFalse);
  });

  test('HU-15 y HU-16: confirmación de reportes y puntos con repositorios '
      'reales', () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );

    expect(sl<ValidacionRepository>(), isA<ValidacionRepositoryImpl>());
    expect(sl<PuntosRepository>(), isA<PuntosRepositoryImpl>());
    expect(sl<GetReportesPorConfirmarUseCase>(),
        same(sl<GetReportesPorConfirmarUseCase>()));
    expect(sl.isRegistered<ConfirmarReporteColaboradorUseCase>(), isTrue);
    expect(sl.isRegistered<GetReportesDeMiComercioUseCase>(), isTrue);
    expect(sl.isRegistered<ConfirmarReporteComercioUseCase>(), isTrue);
    expect(sl.isRegistered<CorregirReporteComercioUseCase>(), isTrue);
    expect(sl.isRegistered<GetResumenPuntosUseCase>(), isTrue);
    expect(sl.isRegistered<GetMovimientosPuntosUseCase>(), isTrue);

    // Cada pantalla tiene su propio Bloc: son fábricas.
    expect(identical(sl<AccionReporteBloc>(), sl<AccionReporteBloc>()), isFalse);
    expect(identical(sl<ResumenPuntosBloc>(), sl<ResumenPuntosBloc>()), isFalse);
    expect(sl<PaginatedBloc<MovimientoPuntos>>(),
        isA<PaginatedBloc<MovimientoPuntos>>());
    // La lista por confirmar sirve para el colaborador y para el comercio.
    expect(sl<PaginatedBloc<ReportePorConfirmar>>(param1: false),
        isA<PaginatedBloc<ReportePorConfirmar>>());
    expect(sl<PaginatedBloc<ReportePorConfirmar>>(param1: true),
        isA<PaginatedBloc<ReportePorConfirmar>>());
  });

  test('HU-19: la ubicación del cliente se arma con las implementaciones '
      'reales', () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );

    expect(sl<UbicacionClienteRepository>(),
        isA<UbicacionClienteRepositoryImpl>());
    expect(sl<Geocodificador>(), isA<GeocodingGeocodificador>());
    expect(sl<GetMiUbicacionUseCase>(), same(sl<GetMiUbicacionUseCase>()));
    expect(sl.isRegistered<GuardarMiUbicacionUseCase>(), isTrue);
    expect(sl.isRegistered<GetComerciosEnRadioUseCase>(), isTrue);
    expect(sl.isRegistered<BuscarDireccionUseCase>(), isTrue);
    expect(identical(sl<MapaComerciosBloc>(), sl<MapaComerciosBloc>()),
        isFalse);
  });

  test('HU-18: la comparación del carrito se arma con el repositorio real',
      () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );

    expect(sl<ComparacionRepository>(), isA<ComparacionRepositoryImpl>());
    expect(sl<GetOfertasCarritoUseCase>(),
        same(sl<GetOfertasCarritoUseCase>()));
    expect(sl.isRegistered<CompararCarritoUseCase>(), isTrue);
    expect(identical(sl<ComparacionBloc>(), sl<ComparacionBloc>()), isFalse);
    expect(identical(sl<PreciosCarritoBloc>(), sl<PreciosCarritoBloc>()),
        isFalse);
  });

  test('llamar dos veces a setupDependencies no duplica los registros', () {
    setupDependencies();

    expect(setupDependencies, returnsNormally);
  });
}
