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
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';
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
                create: (_) => DisponibilidadBloc(
                  cambiar: sl<CambiarDisponibilidadUseCase>(),
                  inicial: args.profile.courierAvailable,
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
            child: RolShell(rol: args.role, profile: args.profile),
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
      AppRoutes.catalogoCsv => BlocProvider(
          create: (_) => sl<CargaCsvBloc>(),
          child: const CatalogoCsvPage(),
        ),
      // HU-12: búsqueda del cliente, detalle del producto y escáner.
      AppRoutes.busqueda => () {
          final texto = args is String ? args : '';
          return BlocProvider(
            create: (_) => sl<PaginatedBloc<ResultadoBusqueda>>(param1: texto)
              ..add(PaginatedStarted()),
            child: BusquedaPage(textoInicial: texto),
          );
        }(),
      AppRoutes.busquedaDetalle when args is ConsultaProducto => BlocProvider(
          create: (_) => sl<DetalleProductoBloc>(param1: args)
            ..add(DetalleProductoStarted()),
          child: const DetalleProductoPage(),
        ),
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
      // El escáner devuelve el código leído.
      AppRoutes.escaner =>
        MaterialPageRoute<String>(builder: (_) => page, settings: settings),
      // El detalle de una solicitud devuelve la decisión tomada.
      AppRoutes.adminSolicitudDetalle => MaterialPageRoute<ApprovalStatus>(
          builder: (_) => page, settings: settings),
      _ => MaterialPageRoute<void>(builder: (_) => page, settings: settings),
    };
  }
}
