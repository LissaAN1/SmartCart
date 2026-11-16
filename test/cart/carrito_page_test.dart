import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/presentation/pages/carrito_page.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/pump_helpers.dart';

/// Monta el carrito con las mismas rutas de apoyo que el resto de pruebas:
/// "Explorar productos" abre una pantalla marcada "EXPLORAR".
Future<(TestEnv, ClienteBlocs)> _pump(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
  bool esperar = true,
}) async {
  setScreenSize(tester, 420, 900);
  final env = TestEnv()..iniciarSesionComoCliente();
  prepare?.call(env);
  final blocs = env.clienteBlocs();
  addTearDown(blocs.cerrar);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: blocs.carrito),
          BlocProvider.value(value: blocs.favoritos),
        ],
        child: const CarritoPage(),
      ),
    ),
  );
  if (esperar) await tester.pumpAndSettle();
  return (env, blocs);
}

void _conLineas(TestEnv env, Map<String, int> cantidades) {
  cantidades.forEach((id, cantidad) {
    env.cliente.carrito.lineas
        .add(env.cliente.carrito.disponibles[id]!.toLinea(cantidad));
  });
}

IconButton _boton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(find.widgetWithIcon(IconButton, _iconoDe(tooltip)));

IconData _iconoDe(String tooltip) => switch (tooltip) {
      'Disminuir cantidad' => Icons.remove_circle_outline,
      'Aumentar cantidad' => Icons.add_circle_outline,
      _ => Icons.delete_outline,
    };

void main() {
  group('Carrito · estados', () {
    testWidgets('mientras lee el carrito muestra el indicador', (tester) async {
      final gate = Completer<void>();
      await _pump(
        tester,
        prepare: (env) => env.cliente.carrito.gateObtener = gate,
        esperar: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Tu carrito está vacío'), findsOneWidget);
    });

    testWidgets('sin productos lo dice y ofrece explorar', (tester) async {
      await _pump(tester);

      expect(find.text('Mi carrito'), findsOneWidget);
      expect(find.text('Tu carrito está vacío'), findsOneWidget);

      await tester.tap(find.text('Explorar productos'));
      await tester.pumpAndSettle();

      expect(find.text('EXPLORAR'), findsOneWidget);
    });

    testWidgets('si no se puede leer muestra el error y deja reintentar',
        (tester) async {
      final (env, _) = await _pump(
        tester,
        prepare: (env) => env.cliente.carrito.obtenerError =
            const AuthFailure('No pudimos conectarnos.'),
      );
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      env.cliente.carrito.obtenerError = null;
      _conLineas(env, {'p1': 1});
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
    });
  });

  group('Carrito · lo que muestra', () {
    testWidgets('cada producto con su marca, categoría, comercio y cantidad',
        (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 2}));

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Diana · Super'), findsOneWidget);
      expect(find.text('Vende Minimercado La Esquina'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('un producto sin marca muestra solo la categoría', (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p3': 1}));

      expect(find.text('Café'), findsOneWidget);
    });

    testWidgets('el carrito muestra la cantidad de productos y de unidades',
        (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 2, 'p2': 1}));

      expect(find.text('2 productos · 3 unidades'), findsOneWidget);
    });

    testWidgets('con un solo producto y una unidad usa el singular',
        (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 1}));

      expect(find.text('1 producto · 1 unidad'), findsOneWidget);
    });

    testWidgets('ofrece agregar más productos', (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 1}));

      await tester.tap(find.text('Agregar más productos'));
      await tester.pumpAndSettle();

      expect(find.text('EXPLORAR'), findsOneWidget);
    });
  });

  group('Carrito · escenario 2: cambiar la cantidad', () {
    testWidgets('aumentar actualiza la cantidad y el resumen', (tester) async {
      final (env, _) =
          await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 2}));

      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1 producto · 3 unidades'), findsOneWidget);
      expect(env.cliente.carrito.lineas.single.cantidad, 3);
    });

    testWidgets('disminuir baja la cantidad', (tester) async {
      final (env, _) =
          await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 3}));

      await tester.tap(find.byTooltip('Disminuir cantidad'));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(env.cliente.carrito.lineas.single.cantidad, 2);
    });

    testWidgets('con 1 unidad no se puede disminuir más', (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 1}));

      expect(_boton(tester, 'Disminuir cantidad').onPressed, isNull);
      expect(_boton(tester, 'Aumentar cantidad').onPressed, isNotNull);
    });

    testWidgets('con 99 unidades no se puede aumentar más', (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 99}));

      expect(_boton(tester, 'Aumentar cantidad').onPressed, isNull);
      expect(_boton(tester, 'Disminuir cantidad').onPressed, isNotNull);
    });

    testWidgets('cada producto cambia su propia cantidad', (tester) async {
      final (env, _) = await _pump(
        tester,
        prepare: (env) => _conLineas(env, {'p1': 1, 'p2': 1}),
      );

      await tester.tap(find.byTooltip('Aumentar cantidad').first);
      await tester.pumpAndSettle();

      final cantidades = {
        for (final l in env.cliente.carrito.lineas) l.idProducto: l.cantidad,
      };
      expect(cantidades.values.toSet(), {1, 2});
      expect(find.text('2 productos · 3 unidades'), findsOneWidget);
    });

    testWidgets('si no se pudo guardar vuelve la cantidad anterior y avisa',
        (tester) async {
      final (env, _) =
          await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 2}));
      env.cliente.carrito.cambiarError =
          const AuthFailure('No pudimos guardar o leer tus datos.');

      await tester.tap(find.byTooltip('Aumentar cantidad'));
      await tester.pumpAndSettle();

      expect(find.text('No pudimos guardar o leer tus datos.'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });
  });

  group('Carrito · quitar productos', () {
    testWidgets('quitar un producto lo saca del carrito', (tester) async {
      final (env, _) = await _pump(
        tester,
        prepare: (env) => _conLineas(env, {'p1': 1, 'p2': 1}),
      );

      await tester.tap(find.byTooltip('Quitar del carrito').first);
      await tester.pumpAndSettle();

      expect(find.text('1 producto · 1 unidad'), findsOneWidget);
      expect(env.cliente.carrito.lineas.length, 1);
    });

    testWidgets('quitar el último deja el carrito vacío', (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 1}));

      await tester.tap(find.byTooltip('Quitar del carrito'));
      await tester.pumpAndSettle();

      expect(find.text('Tu carrito está vacío'), findsOneWidget);
    });

    testWidgets('si no se pudo quitar, el producto vuelve y se avisa',
        (tester) async {
      final (env, _) =
          await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 1}));
      env.cliente.carrito.quitarError =
          const AuthFailure('No pudimos guardar o leer tus datos.');

      await tester.tap(find.byTooltip('Quitar del carrito'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('No pudimos guardar o leer tus datos.'), findsOneWidget);
    });
  });

  group('Carrito · se recupera al volver a abrir la app', () {
    testWidgets('un carrito guardado aparece apenas se abre la pantalla',
        (tester) async {
      await _pump(tester, prepare: (env) => _conLineas(env, {'p1': 4, 'p2': 2}));

      expect(find.text('2 productos · 6 unidades'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });
}
