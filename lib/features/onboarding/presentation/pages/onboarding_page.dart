import 'package:flutter/material.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/onboarding/presentation/pages/pantalla_bienvenida.dart';
import 'package:smartcart/features/onboarding/presentation/pages/pantalla_comparacion.dart';

/// Contenedor de las dos pantallas de bienvenida. Solo guarda cuál se ve.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _pagina = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _irA(int pagina) {
    _controller.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _terminar() {
    // Con pushReplacement el botón "atrás" no regresa a la bienvenida.
    Navigator.pushReplacementNamed(context, AppRoutes.profileSelection);
  }

  @override
  Widget build(BuildContext context) {
    // En la segunda pantalla "atrás" vuelve a la primera en vez de salir.
    return PopScope(
      canPop: _pagina == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irA(0);
      },
      child: Scaffold(
        body: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _pagina = i),
          children: [
            PantallaBienvenida(onContinuar: () => _irA(1)),
            PantallaComparacion(onSiguiente: _terminar),
          ],
        ),
      ),
    );
  }
}