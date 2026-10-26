import 'package:flutter/material.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';

/// Datos que necesita la ruta [AppRoutes.home]: con qué perfil entró la
/// persona y quién es. Viajan como argumento porque ya se leyeron al iniciar
/// sesión o al recuperar la sesión guardada.
class HomeArguments {
  final UserRole role;
  final Profile profile;

  const HomeArguments({required this.role, required this.profile});
}

/// Atajos de navegación usados por varias pantallas. Reemplazan toda la pila
/// porque desde estos puntos no se debe poder volver con "atrás" (por ejemplo,
/// del Home al login).
extension AppNavigation on BuildContext {
  void goHome({required UserRole role, required Profile profile}) {
    Navigator.of(this).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
      arguments: HomeArguments(role: role, profile: profile),
    );
  }

  void goProfileSelection() {
    Navigator.of(this).pushNamedAndRemoveUntil(
      AppRoutes.profileSelection,
      (route) => false,
    );
  }
}
