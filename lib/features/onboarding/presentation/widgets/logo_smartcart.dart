import 'package:flutter/material.dart';
import 'package:smartcart/core/constants/app_assets.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Logo de SmartCart para el fondo verde de la bienvenida.
class LogoSmartCart extends StatelessWidget {
  final double tamano;

  const LogoSmartCart({super.key, this.tamano = 96});

  @override
  Widget build(BuildContext context) {
    final tema = TemaRol.of(context);
    return Semantics(
      label: 'Logo de SmartCart',
      excludeSemantics: true,
      child: Image.asset(
        AppAssets.logoSmartcart,
        width: tamano,
        height: tamano,
        fit: BoxFit.contain,
        // Si la imagen no carga, se dibuja el logo con un ícono.
        errorBuilder: (_, __, ___) => Container(
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
      ),
    );
  }
}