import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/favoritos/presentation/pages/favoritos_page.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pump(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
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
        child: FavoritosPage(
          crearProductos: env.favoritosProductosBloc,
          crearComercios: env.favoritosComerciosBloc,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _irAComercios(WidgetTester tester) async {
  await tester.tap(find.text('Comercios'));
  await tester.pumpAndSettle();
}

void main() {
  group('Favoritos · productos', () {
    testWidgets('lista los productos favoritos, el más reciente primero',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) =>
            env.cliente.favoritos.precargar(productos: ['p2', 'p1']),
      );

      expect(find.text('Mis favoritos'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Vende Minimercado La Esquina'), findsNWidgets(2));
      // `precargar` recibe los ids del más reciente al más antiguo: la leche
      // (p2) es la más reciente y sale primero.
      expect(
        tester.getTopLeft(find.text('Leche entera 1 L')).dy,
        lessThan(tester.getTopLeft(find.text('Arroz blanco 500 g')).dy),
      );
    });

    testWidgets('cada producto aparece como favorito (corazón lleno)',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.precargar(productos: ['p1']),
      );

      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
      expect(find.byTooltip('Guardar en favoritos'), findsNothing);
    });

    testWidgets('sin favoritos invita a guardar uno', (tester) async {
      await _pump(tester);

      expect(find.textContaining('Aún no tienes productos favoritos'),
          findsOneWidget);
    });

    testWidgets('quitar el corazón saca el producto de la lista',
        (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) =>
            env.cliente.favoritos.precargar(productos: ['p2', 'p1']),
      );

      await tester.tap(find.byTooltip('Quitar de favoritos').first);
      await tester.pumpAndSettle();

      expect(env.cliente.favoritos.idsDeProductos.length, 1);
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
      expect(find.text('Quitado de tus favoritos'), findsOneWidget);
    });

    testWidgets('desde favoritos se puede agregar el producto al carrito',
        (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.precargar(productos: ['p1']),
      );

      await tester.tap(find.byTooltip('Agregar al carrito'));
      await tester.pumpAndSettle();

      expect(env.cliente.carrito.lineas.single.idProducto, 'p1');
      expect(find.text('"Arroz blanco 500 g" se agregó al carrito'),
          findsOneWidget);
    });

    testWidgets('si la carga falla deja reintentar', (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) =>
            env.cliente.favoritos.listError = const AuthFailure('No pudimos conectarnos.'),
      );
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      env.cliente.favoritos
        ..listError = null
        ..precargar(productos: ['p1']);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
    });
  });

  group('Favoritos · comercios', () {
    testWidgets('lista los comercios favoritos con su dirección', (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.precargar(comercios: ['c2']),
      );

      await _irAComercios(tester);

      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(find.text('Carrera 5 # 10-20 · Bogotá'), findsOneWidget);
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    });

    testWidgets('sin favoritos invita a guardar uno', (tester) async {
      await _pump(tester);

      await _irAComercios(tester);

      expect(find.textContaining('Aún no tienes comercios favoritos'),
          findsOneWidget);
    });

    testWidgets('quitar el corazón saca el comercio de la lista', (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.precargar(comercios: ['c1']),
      );
      await _irAComercios(tester);

      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pumpAndSettle();

      expect(env.cliente.favoritos.idsDeComercios, isEmpty);
      expect(find.textContaining('Aún no tienes comercios favoritos'),
          findsOneWidget);
    });
  });
}
