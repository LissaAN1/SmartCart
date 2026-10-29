import 'package:flutter/material.dart';

/// Puntos de progreso del onboarding. El punto activo puede verse alargado.
class IndicadorProgreso extends StatelessWidget {
  final int total;
  final int actual;
  final Color colorActivo;
  final Color colorInactivo;
  final bool alargado;

  const IndicadorProgreso({
    super.key,
    required this.total,
    required this.actual,
    required this.colorActivo,
    required this.colorInactivo,
    this.alargado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${actual + 1} de $total',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == actual && alargado ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == actual ? colorActivo : colorInactivo,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}