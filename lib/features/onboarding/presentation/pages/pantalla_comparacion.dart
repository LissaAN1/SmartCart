import 'package:flutter/material.dart';
import 'package:smartcart/core/constants/app_assets.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/onboarding/presentation/widgets/indicador_progreso.dart';

/// Pantalla 2: ilustración, progreso, texto descriptivo y botón "Siguiente".
class PantallaComparacion extends StatelessWidget {
  final VoidCallback onSiguiente;

  const PantallaComparacion({super.key, required this.onSiguiente});

  /// Ancho máximo del contenido en tablet y escritorio.
  static const double _anchoMaximo = 480;

  @override
  Widget build(BuildContext context) {
    final tema = TemaRol.of(context);
    return Container(
      color: tema.fondo,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Semantics(
                            label:
                                'Ilustración de una persona comparando su carrito de compras',
                            child: Image.asset(
                              AppAssets.onboardingComparacion,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              // Si la imagen no carga, la pantalla no se rompe.
                              errorBuilder: (_, __, ___) => Container(
                                height: 220,
                                color: tema.suave,
                                child: Icon(Icons.shopping_cart_outlined,
                                    size: 96, color: tema.primario),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        IndicadorProgreso(
                          total: 3,
                          actual: 0,
                          colorActivo: tema.primario,
                          colorInactivo: tema.borde,
                        ),
                        const SizedBox(height: 24),
                        Text('Compara tu carrito completo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: tema.texto)),
                        const SizedBox(height: 12),
                        Text(
                            'Encuentra la combinación de compra más '
                            'conveniente entre supermercados y tiendas '
                            'cerca de ti.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: tema.textoGris)),
                        const SizedBox(height: 32),
                        BotonPrimario(
                          texto: 'Siguiente',
                          iconoFinal: Icons.chevron_right,
                          onTap: onSiguiente,
                        ),
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