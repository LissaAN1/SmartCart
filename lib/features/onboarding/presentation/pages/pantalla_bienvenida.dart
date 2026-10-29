import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/onboarding/presentation/widgets/indicador_progreso.dart';
import 'package:smartcart/features/onboarding/presentation/widgets/logo_smartcart.dart';

/// Pantalla 1: fondo verde con el logo, el lema y la flecha para continuar.
class PantallaBienvenida extends StatelessWidget {
  final VoidCallback onContinuar;

  const PantallaBienvenida({super.key, required this.onContinuar});

  /// Ancho máximo del contenido en tablet y escritorio.
  static const double _anchoMaximo = 480;

  @override
  Widget build(BuildContext context) {
    final tema = TemaRol.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tema.primario, tema.primarioOscuro],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _anchoMaximo),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        const LogoSmartCart(),
                        const SizedBox(height: 20),
                        const Text('SmartCart',
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 12),
                        const Text('Compara menos,\ndecide mejor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IndicadorProgreso(
                              total: 3,
                              actual: 1,
                              alargado: false,
                              colorActivo: Colors.white,
                              colorInactivo:
                                  Colors.white.withValues(alpha: 0.6),
                            ),
                            IconButton(
                              tooltip: 'Continuar',
                              constraints: const BoxConstraints(
                                  minWidth: 48, minHeight: 48),
                              onPressed: onContinuar,
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white, size: 32),
                            ),
                          ],
                        ),
                        const SizedBox(height: 120),
                        const Text('COLOMBIA',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}