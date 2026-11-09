import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/di/injector.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/aprobaciones/presentation/pages/admin_solicitudes_page.dart';
import 'package:smartcart/features/aprobaciones/presentation/pages/solicitud_detalle_page.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/notificaciones/presentation/widgets/aviso_notificaciones.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
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
      // El detalle de una solicitud devuelve la decisión tomada.
      AppRoutes.adminSolicitudDetalle => MaterialPageRoute<ApprovalStatus>(
          builder: (_) => page, settings: settings),
      _ => MaterialPageRoute<void>(builder: (_) => page, settings: settings),
    };
  }
}
