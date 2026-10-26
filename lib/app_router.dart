import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/login/ui/screens/login_screen.dart';
import 'package:smartcart/features/onboarding/presentation/pages/onboarding_placeholder_page.dart';
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
      AppRoutes.onboarding => const OnboardingPlaceholderPage(),
      AppRoutes.login when args is UserRole => BlocProvider(
          create: (_) => LoginBloc(),
          child: LoginScreen(role: args),
        ),
      AppRoutes.register => BlocProvider(
          create: (_) => RegisterBloc(),
          child: RegisterScreen(initialRole: args is UserRole ? args : null),
        ),
      AppRoutes.home when args is HomeArguments => BlocProvider(
          create: (_) => SessionBloc(),
          child: RolShell(rol: args.role, profile: args.profile),
        ),
      // La selección de perfil también es el destino por defecto: una ruta
      // desconocida o sin los argumentos que necesita no debe romper la app.
      _ => BlocProvider(
          create: (_) => SessionBloc()..add(SessionStarted()),
          child: const ProfileSelectionPage(),
        ),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
