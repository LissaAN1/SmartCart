import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Logo de SmartCart: carrito dentro de un círculo claro sobre un cuadro
/// redondeado translúcido, pensado para el fondo verde de la bienvenida.
class LogoSmartCart extends StatelessWidget {
  final double tamano;

  const LogoSmartCart({super.key, this.tamano = 96});

  @override
  Widget build(BuildContext context) {
    final tema = TemaRol.of(context);
    return Semantics(
      label: 'Logo de SmartCart',
      excludeSemantics: true,
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(tamano * 0.28),
        ),
        child: Center(
          child: CircleAvatar(
            radius: tamano * 0.33,
            backgroundColor: tema.suave,
            child: Icon(
              Icons.shopping_cart_outlined,
              size: tamano * 0.38,
              color: tema.primarioOscuro,
            ),
          ),
        ),
      ),
    );
  }
}