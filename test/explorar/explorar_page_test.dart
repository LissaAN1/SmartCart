import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/explorar/presentation/pages/explorar_page.dart';

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
        child: ExplorarPage(
          crearProductos: env.explorarProductosBloc,
          crearComercios: env.explorarComerciosBloc,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _buscar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField), texto);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _irAComercios(WidgetTester tester) async {
  await tester.tap(find.text('Comercios'));
  await tester.pumpAndSettle();
}

void main() {
  group('Explorar · productos', () {
    testWidgets('lista los productos con el comercio que los vende',
        (tester) async {
      await _pump(tester);

      expect(find.text('Explorar'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Diana · Super'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Café molido 500 g'), findsOneWidget);
      expect(find.text('Vende Tienda Doña Rosa'), findsOneWidget);
    });

    testWidgets('se busca por nombre o marca', (tester) async {
      await _pump(tester);

      await _buscar(tester, 'alpina');

      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsNothing);
    });

    testWidgets('sin coincidencias lo dice', (tester) async {
      await _pump(tester);

      await _buscar(tester, 'zzz');

      expect(find.text('No encontramos productos con "zzz".'), findsOneWidget);
    });

    testWidgets('quitar la búsqueda vuelve a mostrar todo', (tester) async {
      await _pump(tester);
      await _buscar(tester, 'alpina');

      await tester.tap(find.byTooltip('Quitar búsqueda'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
    });

    testWidgets('si la carga falla deja reintentar', (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) => env.cliente.explorar.listError =
            const AuthFailure('No pudimos conectarnos.'),
      );
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      env.cliente.explorar.listError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
    });
  });

  group('Explorar · escenario 1: agregar al carrito', () {
    testWidgets('presionar agregar lo deja en el carrito con cantidad 1',
        (tester) async {
      final env = await _pump(tester);

      await tester.tap(find.byTooltip('Agregar al carrito').first);
      await tester.pumpAndSettle();

      expect(env.cliente.carrito.lineas.single.idProducto, 'p1');
      expect(env.cliente.carrito.lineas.single.cantidad, 1);
      expect(find.text('"Arroz blanco 500 g" se agregó al carrito'),
          findsOneWidget);
    });

    testWidgets('el carrito de la barra muestra cuántos productos hay',
        (tester) async {
      await _pump(tester);
      expect(find.byType(Badge), findsOneWidget);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);

      await tester.tap(find.byTooltip('Agregar al carrito').at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar al carrito').at(1));
      await tester.pumpAndSettle();

      final insignia = tester.widget<Badge>(find.byType(Badge));
      expect(insignia.isLabelVisible, isTrue);
      expect((insignia.label! as Text).data, '2');
    });

    testWidgets('agregar el mismo producto otra vez suma 1 y lo dice',
        (tester) async {
      final env = await _pump(tester);

      await tester.tap(find.byTooltip('Agregar al carrito').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar al carrito').first);
      await tester.pumpAndSettle();

      expect(env.cliente.carrito.lineas.single.cantidad, 2);
      expect(find.textContaining('ahora tienes 2'), findsOneWidget);
    });

    testWidgets('si no se puede agregar avisa el motivo', (tester) async {
      final env = await _pump(tester);
      env.cliente.carrito.disponibles.remove('p1');

      await tester.tap(find.byTooltip('Agregar al carrito').first);
      await tester.pumpAndSettle();

      expect(find.text('Ese producto ya no está disponible.'), findsOneWidget);
      expect(env.cliente.carrito.lineas, isEmpty);
    });

    testWidgets('el ícono del carrito abre el carrito', (tester) async {
      await _pump(tester);

      await tester.tap(find.byTooltip('Ver carrito'));
      await tester.pumpAndSettle();

      expect(find.text('CARRITO'), findsOneWidget);
    });
  });

  group('Explorar · escenario 3: favoritos', () {
    testWidgets('el corazón de un producto lo guarda en favoritos',
        (tester) async {
      final env = await _pump(tester);
      expect(find.byTooltip('Guardar en favoritos'), findsNWidgets(3));

      await tester.tap(find.byTooltip('Guardar en favoritos').first);
      await tester.pumpAndSettle();

      expect(env.cliente.favoritos.idsDeProductos, ['p1']);
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
      expect(find.text('Guardado en tus favoritos'), findsOneWidget);
    });

    testWidgets('presionarlo otra vez lo quita', (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.precargar(productos: ['p1']),
      );

      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pumpAndSettle();

      expect(env.cliente.favoritos.idsDeProductos, isEmpty);
      expect(find.byTooltip('Guardar en favoritos'), findsNWidgets(3));
    });

    testWidgets('los productos que ya eran favoritos se ven marcados',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) =>
            env.cliente.favoritos.precargar(productos: ['p2', 'p3']),
      );

      expect(find.byTooltip('Quitar de favoritos'), findsNWidgets(2));
      expect(find.byTooltip('Guardar en favoritos'), findsOneWidget);
    });

    testWidgets('si no se pudo guardar el corazón vuelve a como estaba',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.cambiarError =
            const AuthFailure('No tienes permiso para realizar esta acción.'),
      );

      await tester.tap(find.byTooltip('Guardar en favoritos').first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Guardar en favoritos'), findsNWidgets(3));
      expect(find.text('No tienes permiso para realizar esta acción.'),
          findsOneWidget);
    });

    testWidgets('el ícono de favoritos abre los favoritos', (tester) async {
      await _pump(tester);

      await tester.tap(find.byTooltip('Mis favoritos'));
      await tester.pumpAndSettle();

      expect(find.text('FAVORITOS'), findsOneWidget);
    });
  });

  group('Explorar · comercios', () {
    testWidgets('lista los comercios', (tester) async {
      await _pump(tester);

      await _irAComercios(tester);

      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(find.text('Calle 10 # 5-20 · Cali'), findsOneWidget);
    });

    testWidgets('se busca por nombre o ciudad', (tester) async {
      await _pump(tester);
      await _irAComercios(tester);

      await _buscar(tester, 'bogotá');

      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsNothing);
    });

    testWidgets('el corazón de un comercio lo guarda en favoritos',
        (tester) async {
      final env = await _pump(tester);
      await _irAComercios(tester);

      await tester.tap(find.byTooltip('Guardar en favoritos').first);
      await tester.pumpAndSettle();

      expect(env.cliente.favoritos.idsDeComercios, ['c1']);
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    });

    testWidgets('sin coincidencias lo dice', (tester) async {
      await _pump(tester);
      await _irAComercios(tester);

      await _buscar(tester, 'zzz');

      expect(find.text('No encontramos comercios con "zzz".'), findsOneWidget);
    });

    testWidgets('un comercio favorito y un producto del mismo comercio no se '
        'confunden', (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.cliente.favoritos.precargar(comercios: ['c1']),
      );

      // En la pestaña de productos ningún corazón está marcado.
      expect(find.byTooltip('Quitar de favoritos'), findsNothing);

      await _irAComercios(tester);
      expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    });
  });
}
