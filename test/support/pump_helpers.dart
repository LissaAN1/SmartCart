import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';

/// Fija el tamaño lógico de la ventana de prueba (devicePixelRatio = 1).
void setScreenSize(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Rutas de apoyo: marcan en pantalla a dónde se navegó, con sus argumentos.
Route<dynamic>? stubRoutes(RouteSettings settings) {
  final args = settings.arguments;
  final label = switch (settings.name) {
    AppRoutes.home when args is HomeArguments => 'HOME ${args.role.name}',
    AppRoutes.login => 'LOGIN $args',
    AppRoutes.register => 'REGISTER $args',
    AppRoutes.profileSelection => 'SELECTION',
    _ => null,
  };
  if (label == null) return null;
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => Scaffold(body: Text(label)),
  );
}
