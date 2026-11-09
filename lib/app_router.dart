import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/di/injector.dart';
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
          ],
          child: RolShell(rol: args.role, profile: args.profile),
        ),
      // La selección de perfil también es el destino por defecto: una ruta
      // desconocida o sin los argumentos que necesita no debe romper la app.
      _ => BlocProvider(
          create: (_) => sl<SessionBloc>()..add(SessionStarted()),
          child: const ProfileSelectionPage(),
        ),
    };
    // El onboarding del colaborador devuelve el perfil actualizado al cerrarse
    // (`Navigator.pop(context, profile)`), así que su ruta lleva ese tipo.
    if (settings.name == AppRoutes.colaboradorOnboarding) {
      return MaterialPageRoute<Profile>(builder: (_) => page, settings: settings);
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}