import 'package:flutter/material.dart';
import 'package:smartcart/core/routes/app_routes.dart';

/// MARCADOR TEMPORAL de las pantallas 1 y 2 de bienvenida, que desarrolla
/// otra persona del equipo.
///
/// Para reemplazarlo: cambiar el builder de [AppRoutes.onboarding] en
/// `AppRouter` por las pantallas reales, apuntar `AppRoutes.initial` a
/// [AppRoutes.onboarding] y, al terminar, ir a la selección de perfil con
/// `Navigator.pushReplacementNamed(context, AppRoutes.profileSelection)`.
class OnboardingPlaceholderPage extends StatelessWidget {
  const OnboardingPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pantallas de bienvenida pendientes'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.profileSelection,
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
