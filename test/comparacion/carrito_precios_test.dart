import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/cart/presentation/pages/carrito_page.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/fakes_comparacion.dart';
import '../support/pump_helpers.dart';

/// Carrito con 3 arroces (p1, en promoción a $ 4.000) y 1 leche (p2,
/// agotada en su comercio).
Future<(TestEnv, ClienteBlocs)> _pump(WidgetTester tester,
    {double ancho = 420}) async {
  setScreenSize(tester, ancho, 1200);
  final env = TestEnv()..iniciarSesionComoCliente();
  env.cliente.carrito.lineas
    ..add(arrozCliente.toLinea(3))
    ..add(lecheCliente.toLinea(1));
  env.comparacion.lineas = [
    linea('p1', 'Arroz blanco 500 g', 3, [
      oferta('p1', 'A', 4000, enPromocion: true, precioNormal: 5000),
      oferta('p1-b', 'B', 3800),
    ]),
    linea('p2', 'Leche entera 1 L', 1, [
      oferta('p2', 'A', 4100, disponible: false),
    ]),
  ];
  final blocs = env.clienteBlocs();
  addTearDown(blocs.cerrar);
  final precios = env.preciosCarritoBloc()..add(PreciosCarritoSolicitados());
  addTearDown(precios.close);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: blocs.carrito),
          BlocProvider.value(value: blocs.favoritos),
          BlocProvider.value(value: precios),
        ],
        child: const CarritoPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (env, blocs);
}

void main() {
  testWidgets('muestra el precio vigente, el subtotal de cada línea y el '
      'total en COP', (tester) async {
    await _pump(tester);

    expect(find.text('\$ 4.000 c/u · Promoción'), findsOneWidget);
    expect(find.text('\$ 12.000'), findsNWidgets(2)); // subtotal y total
    expect(find.text('Agotado en este comercio'), findsOneWidget);
    expect(find.text('Total estimado'), findsOneWidget);
    expect(find.text('1 producto sin precio no se suma.'), findsOneWidget);
  });

  testWidgets('al cambiar la cantidad el subtotal y el total se actualizan',
      (tester) async {
    await _pump(tester);

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('\$ 16.000'), findsNWidgets(2));
  });

  testWidgets('un producto nuevo en el carrito pide su precio', (tester) async {
    final (env, blocs) = await _pump(tester);
    expect(env.comparacion.llamadas, 1);

    // En la base, el carrito ya trae el café con su oferta.
    env.comparacion.lineas = [
      ...env.comparacion.lineas,
      linea('p3', 'Café molido 500 g', 1, [oferta('p3', 'B', 12000)]),
    ];
    blocs.carrito.add(CarritoProductoAgregado('p3'));
    await tester.pumpAndSettle();

    expect(env.comparacion.llamadas, 2);
    expect(find.text('\$ 12.000 c/u'), findsOneWidget);
    expect(find.text('\$ 24.000'), findsOneWidget);
  });

  testWidgets('"Comparar carrito" abre la comparación', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.text('Comparar carrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparar carrito'));
    await tester.pumpAndSettle();

    expect(find.text('COMPARACION'), findsOneWidget);
  });

  testWidgets('en 320 px no hay desbordes', (tester) async {
    await _pump(tester, ancho: 320);

    expect(tester.takeException(), isNull);
  });
}
