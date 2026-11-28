import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/di/injector.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/aprobaciones/presentation/pages/admin_solicitudes_page.dart';
import 'package:smartcart/features/aprobaciones/presentation/pages/solicitud_detalle_page.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/notificaciones/presentation/widgets/aviso_notificaciones.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/catalog/presentation/pages/catalogo_csv_page.dart';
import 'package:smartcart/features/catalog/presentation/pages/catalogo_page.dart';
import 'package:smartcart/features/catalog/presentation/pages/producto_form_page.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/pages/busqueda_page.dart';
import 'package:smartcart/features/busqueda/presentation/pages/detalle_producto_page.dart';
import 'package:smartcart/features/busqueda/presentation/pages/escaner_page.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/pages/colaborador_home_screen.dart';
import 'package:smartcart/features/colaborador/presentation/pages/colaborador_onboarding_page.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/login/ui/screens/login_screen.dart';
import 'package:smartcart/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:smartcart/features/profile_selection/presentation/pages/profile_selection_page.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/register/ui/screens/register_screen.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/calificaciones/presentation/bloc/calificar_orden_bloc.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_args.dart';
import 'package:smartcart/features/calificaciones/presentation/pages/calificar_orden_page.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/presentation/bloc/confirmar_compra_bloc.dart';
import 'package:smartcart/features/orders/presentation/pages/confirmar_compra_page.dart';
import 'package:smartcart/features/orders/presentation/pages/mis_ordenes_page.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/cart/presentation/pages/carrito_page.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/explorar/presentation/pages/explorar_page.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';
import 'package:smartcart/features/favoritos/presentation/pages/favoritos_page.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/presentation/bloc/resumen_puntos_bloc.dart';
import 'package:smartcart/features/puntos/presentation/pages/mis_puntos_page.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/presentation/bloc/accion_reporte_bloc.dart';
import 'package:smartcart/features/reportes/presentation/pages/reportes_por_confirmar_page.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/presentation/bloc/reporte_form_bloc.dart';
import 'package:smartcart/features/reportes/presentation/bloc/sugerencia_bloc.dart';
import 'package:smartcart/features/reportes/presentation/pages/escaner_codigo_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/mis_reportes_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_args.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_establecimiento_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_form_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_producto_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/sugerir_establecimiento_page.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/pages/alternativa_detalle_page.dart';
import 'package:smartcart/features/comparacion/presentation/pages/comparacion_page.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';
import 'package:smartcart/features/ubicacion/presentation/pages/mapa_comercios_page.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_event.dart';

/// BLoC no es una pantalla ni una base de datos. 
/// Es un componente que administra la lógica y los cambios de estado de una funcionalidad.

/// Resuelve cada ruta y le da a cada pantalla su Bloc, como hacíamos 
///en los laboratorios. Se usa `onGenerateRoute` porque
/// login, registro y Home reciben argumentos tipados.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      AppRoutes.onboarding => const OnboardingPage(),
      AppRoutes.login when args is UserRole => BlocProvider(
          create: (_) => sl<LoginBloc>(),
          child: LoginScreen(role: args),
        ),
      AppRoutes.register => BlocProvider(
          create: (_) => sl<RegisterBloc>(),
          child: RegisterScreen(initialRole: args is UserRole ? args : null),
        ),
      AppRoutes.colaboradorOnboarding => BlocProvider(
          create: (_) => sl<ColaboradorOnboardingBloc>(),
          child: const ColaboradorOnboardingPage(),
        ),
      AppRoutes.home when args is HomeArguments => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<SessionBloc>()),
            // HU-07: solo el comercio necesita saber si ya registró su
            // establecimiento y en qué estado está.
            // La disponibilidad del repartidor es real: arranca con lo guardado.
            if (args.role == UserRole.repartidor)
              BlocProvider(
                create: (_) => sl<DisponibilidadBloc>(
                  param1: args.profile.courierAvailable,
                ),
              ),
            if (args.role == UserRole.comercio)
              BlocProvider(
                create: (_) => sl<ComercioBloc>()..add(ComercioStarted()),
              ),
            // HU-24: al entrar se muestran las notificaciones sin leer (por
            // ejemplo, la decisión del administrador).
            BlocProvider(
              create: (_) =>
                  sl<NotificacionesBloc>()..add(NotificacionesStarted()),
            ),
          ],
          child: AvisoNotificaciones(
            child: RolShell(
              rol: args.role,
              profile: args.profile,
              // HU-14: el Home del colaborador muestra sus últimos reportes
              // reales (los más recientes).
              // HU-17: el carrito y los favoritos del cliente, compartidos por
              // todas sus pantallas.
              crearCliente: args.role == UserRole.cliente
                  ? () => ClienteBlocs(
                        carrito: sl<CarritoBloc>(),
                        favoritos: sl<FavoritosBloc>(),
                      )
                  : null,
              crearMisReportes: args.role == UserRole.colaborador
                  ? () => sl<PaginatedBloc<MiReporte>>(
                        param1: ColaboradorHomeScreen.reportesEnHome,
                      )
                  : null,
            ),
          ),
        ),
      AppRoutes.adminSolicitudes => AdminSolicitudesPage(
          crearLista: (tipo) => sl<PaginatedBloc<Solicitud>>(param1: tipo),
        ),
      AppRoutes.adminSolicitudDetalle when args is Solicitud => BlocProvider(
          create: (_) => sl<DecisionSolicitudBloc>(param1: args),
          child: const SolicitudDetallePage(),
        ),
      AppRoutes.catalogo => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  sl<PaginatedBloc<Producto>>()..add(PaginatedStarted()),
            ),
            // HU-11: chips de categorías, resumen e interruptor de cada fila.
            BlocProvider(
              create: (_) => sl<InventarioBloc>()..add(InventarioStarted()),
            ),
          ],
          child: const CatalogoPage(),
        ),
      AppRoutes.catalogoProducto => () {
          final producto = args is Producto ? args : null;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => sl<ProductoFormBloc>(param1: producto)
                  ..add(ProductoFormStarted()),
              ),
              // HU-11: historial, disponibilidad y promoción del producto
              // que se edita (uno nuevo todavía no tiene).
              if (producto != null)
                BlocProvider(
                  create: (_) => sl<PrecioProductoBloc>(param1: producto)
                    ..add(PrecioProductoStarted()),
                ),
            ],
            child: ProductoFormPage(producto: producto),
          );
        }(),
      // HU-14: flujo del reporte de precio del colaborador.
      AppRoutes.reporteEstablecimiento => BlocProvider(
          create: (_) => sl<UbicacionBloc>()..add(UbicacionSolicitada()),
          child: ReporteEstablecimientoPage(
            crearLista: (ubicacion) =>
                sl<PaginatedBloc<EstablecimientoCercano>>(param1: ubicacion),
          ),
        ),
      AppRoutes.reporteProducto when args is EstablecimientoCercano =>
        ReporteProductoPage(
          establecimiento: args,
          crearLista: (idComercio, consulta) => sl<PaginatedBloc<Producto>>(
            instanceName: InstanciasSl.busquedaProductos,
            param1: idComercio,
            param2: consulta,
          ),
        ),
      AppRoutes.reporteFormulario when args is ReporteFormArgs => BlocProvider(
          create: (_) => sl<ReporteFormBloc>(),
          child: ReporteFormPage(args: args),
        ),
      AppRoutes.reporteSugerir => BlocProvider(
          create: (_) => sl<SugerenciaBloc>(),
          child: const SugerirEstablecimientoPage(),
        ),
      AppRoutes.reporteEscaner => const EscanerCodigoPage(),
      // HU-17: pantallas del cliente. Reciben el carrito y los favoritos ya
      // creados por el RolShell y no los cierran.
      // HU-18: el carrito muestra el precio de cada producto y el total.
      AppRoutes.carrito when args is ClienteBlocs => _conBlocsDelCliente(
          args,
          BlocProvider(
            create: (_) =>
                sl<PreciosCarritoBloc>()..add(PreciosCarritoSolicitados()),
            child: const CarritoPage(),
          ),
        ),
      // HU-18: comparación del carrito completo y detalle de una alternativa.
      AppRoutes.comparacion when args is ClienteBlocs => _conBlocsDelCliente(
          args,
          BlocProvider(
            create: (_) => sl<ComparacionBloc>()..add(ComparacionIniciada()),
            child: const ComparacionPage(),
          ),
        ),
      AppRoutes.comparacionDetalle when args is AlternativaArgs =>
        AlternativaDetallePage(args: args),
      // HU-18 + HU-20: confirmar la alternativa elegida en la comparación.
      AppRoutes.confirmarCompra when args is ConBlocsDelCliente =>
        _conBlocsDelCliente(
          args.blocs,
          BlocProvider(
            create: (_) => sl<ConfirmarCompraBloc>()
              ..add(ConfirmarCompraStarted(args.argumento as SeleccionCompra?)),
            child: const ConfirmarCompraPage(),
          ),
        ),
      // HU-20: confirmar la compra; al terminar relee el carrito (ya vacío).
      AppRoutes.confirmarCompra when args is ClienteBlocs => _conBlocsDelCliente(
          args,
          BlocProvider(
            create: (_) =>
                sl<ConfirmarCompraBloc>()..add(ConfirmarCompraStarted()),
            child: const ConfirmarCompraPage(),
          ),
        ),
      AppRoutes.misOrdenes => BlocProvider(
          create: (_) => sl<PaginatedBloc<Orden>>()..add(PaginatedStarted()),
          child: const MisOrdenesPage(),
        ),
      // HU-25: calificar al comercio o al repartidor.
      AppRoutes.calificarOrden when args is CalificarOrdenArgs => BlocProvider(
          create: (_) => sl<CalificarOrdenBloc>(
            param1: args.idOrden,
            param2: args.tipo,
          ),
          child: CalificarOrdenPage(args: args),
        ),
      AppRoutes.favoritos when args is ClienteBlocs => _conBlocsDelCliente(
          args,
          FavoritosPage(
            crearProductos: () => sl<PaginatedBloc<ProductoConComercio>>(
              instanceName: InstanciasSl.favoritosProductos,
            ),
            crearComercios: () => sl<PaginatedBloc<ComercioResumen>>(
              instanceName: InstanciasSl.favoritosComercios,
            ),
          ),
        ),
      AppRoutes.explorar when args is ClienteBlocs => _conBlocsDelCliente(
          args,
          ExplorarPage(
            crearProductos: (texto) => sl<PaginatedBloc<ProductoConComercio>>(
              instanceName: InstanciasSl.explorarProductos,
              param1: texto,
            ),
            crearComercios: (texto) => sl<PaginatedBloc<ComercioResumen>>(
              instanceName: InstanciasSl.explorarComercios,
              param1: texto,
            ),
          ),
        ),
      AppRoutes.misReportes => BlocProvider(
          create: (_) => sl<PaginatedBloc<MiReporte>>(
            param1: PageRequest.defaultPageSize,
          )..add(PaginatedStarted()),
          child: const MisReportesPage(),
        ),
      // HU-15: reportes que esperan confirmación (colaborador y comercio).
      AppRoutes.reportesPorConfirmar => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  sl<PaginatedBloc<ReportePorConfirmar>>(param1: false)
                    ..add(PaginatedStarted()),
            ),
            BlocProvider(create: (_) => sl<AccionReporteBloc>()),
          ],
          child: const ReportesPorConfirmarPage(),
        ),
      AppRoutes.reportesComunidad => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  sl<PaginatedBloc<ReportePorConfirmar>>(param1: true)
                    ..add(PaginatedStarted()),
            ),
            BlocProvider(create: (_) => sl<AccionReporteBloc>()),
          ],
          child: const ReportesPorConfirmarPage(esComercio: true),
        ),
      // HU-16: puntos, nivel, reputación e historial.
      AppRoutes.misPuntos => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  sl<ResumenPuntosBloc>()..add(ResumenPuntosStarted()),
            ),
            BlocProvider(
              create: (_) => sl<PaginatedBloc<MovimientoPuntos>>()
                ..add(PaginatedStarted()),
            ),
          ],
          child: const MisPuntosPage(),
        ),
      // HU-19: ubicación, radio y comercios cercanos del cliente.
      AppRoutes.mapaComercios => BlocProvider(
          create: (_) => sl<MapaComerciosBloc>()..add(MapaIniciado()),
          child: const MapaComerciosPage(),
        ),
      AppRoutes.catalogoCsv => BlocProvider(
          create: (_) => sl<CargaCsvBloc>(),
          child: const CatalogoCsvPage(),
        ),
      // HU-12: búsqueda del cliente, detalle del producto y escáner. Desde el
      // Home del cliente llegan con su carrito y sus favoritos (HU-13), para
      // poder agregar y guardar desde el detalle; sin ellos funcionan igual.
      AppRoutes.busqueda => () {
          final (propio, blocs) = desempacarArgumentos(args);
          final texto = propio is String ? propio : '';
          final pagina = BlocProvider(
            create: (_) => sl<PaginatedBloc<ResultadoBusqueda>>(param1: texto)
              ..add(PaginatedStarted()),
            child: BusquedaPage(textoInicial: texto),
          );
          return blocs == null ? pagina : _conBlocsDelCliente(blocs, pagina);
        }(),
      AppRoutes.busquedaDetalle
          when desempacarArgumentos(args).$1 is ConsultaProducto =>
        () {
          final (propio, blocs) = desempacarArgumentos(args);
          final pagina = BlocProvider(
            create: (_) => sl<DetalleProductoBloc>(
                param1: propio as ConsultaProducto)
              ..add(DetalleProductoStarted()),
            child: const DetalleProductoPage(),
          );
          return blocs == null ? pagina : _conBlocsDelCliente(blocs, pagina);
        }(),
      AppRoutes.escaner => const EscanerPage(),
      // La selección de perfil también es el destino por defecto: una ruta
      // desconocida o sin los argumentos que necesita no debe romper la app.
      _ => BlocProvider(
          create: (_) => sl<SessionBloc>()..add(SessionStarted()),
          child: const ProfileSelectionPage(),
        ),
    };
    // Las rutas que devuelven un resultado al cerrarse llevan su tipo; si no,
    // `pushNamed<T>` falla al recibirlo.
    return switch (settings.name) {
      // El onboarding devuelve el perfil ya con el rol colaborador.
      AppRoutes.colaboradorOnboarding =>
        MaterialPageRoute<Profile>(builder: (_) => page, settings: settings),
      // El formulario del producto devuelve si hubo cambios (guardar o
      // eliminar) para que el catálogo recargue su lista.
      AppRoutes.catalogoProducto =>
        MaterialPageRoute<bool>(builder: (_) => page, settings: settings),
      // Los pasos del reporte devuelven `true` si el reporte se envió, para
      // que los pasos anteriores se cierren.
      AppRoutes.reporteEstablecimiento ||
      AppRoutes.reporteProducto ||
      AppRoutes.reporteFormulario ||
      AppRoutes.reporteSugerir =>
        MaterialPageRoute<bool>(builder: (_) => page, settings: settings),
      // Los escáneres (reporte de precio y búsqueda) devuelven el código leído.
      AppRoutes.reporteEscaner ||
      AppRoutes.escaner =>
        MaterialPageRoute<String>(builder: (_) => page, settings: settings),
      // Calificar devuelve `true` si se envió, para que la lista se relea.
      AppRoutes.calificarOrden =>
        MaterialPageRoute<bool>(builder: (_) => page, settings: settings),
      // El detalle de una solicitud devuelve la decisión tomada.
      AppRoutes.adminSolicitudDetalle => MaterialPageRoute<ApprovalStatus>(
          builder: (_) => page, settings: settings),
      _ => MaterialPageRoute<void>(builder: (_) => page, settings: settings),
    };
  }

  /// Entrega el carrito y los favoritos del cliente a una pantalla con
  /// `BlocProvider.value`: ya los creó el `RolShell`, que es quien los cierra.
  static Widget _conBlocsDelCliente(ClienteBlocs blocs, Widget pagina) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CarritoBloc>.value(value: blocs.carrito),
        BlocProvider<FavoritosBloc>.value(value: blocs.favoritos),
      ],
      child: pagina,
    );
  }
}
