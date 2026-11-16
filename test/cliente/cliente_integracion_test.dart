import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/home/presentation/pages/role_shell.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/pump_helpers.dart';

/// Monta el Home del cliente dentro del `RolShell`, con el carrito y los
/// favoritos que el `AppRouter` le daría. Con [conCliente] en `false` simula
/// un `RolShell` sin ellos, como en las pruebas de navegación.
Future<(TestEnv, ClienteBlocs?)> _pumpShell(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
  bool conCliente = true,
}) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv()..iniciarSesionComoCliente();
  prepare?.call(env);
  ClienteBlocs? blocs;

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: BlocProvider<SessionBloc>(
        create: (_) => env.sessionBloc(),
        child: RolShell(
          rol: UserRole.cliente,
          profile: profileWith({UserRole.cliente}),
          crearCliente: conCliente ? () => blocs = env.clienteBlocs() : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (env, blocs);
}

/// El número que muestra la pestaña "Carrito" de la barra inferior, o `null`
/// si no muestra ninguno.
int? _insigniaDelCarrito(WidgetTester tester) {
  final barra = tester.widget<BarraNavRol>(find.byType(BarraNavRol));
  final carrito = barra.items.firstWhere((i) => i.etiqueta == 'Carrito');
  return carrito.badge == 0 ? null : carrito.badge;
}

void main() {
  group('Home del cliente · carrito', () {
    testWidgets('sin productos la pestaña Carrito no muestra número',
        (tester) async {
      await _pumpShell(tester);

      expect(_insigniaDelCarrito(tester), isNull);
    });

    testWidgets('un carrito guardado se recupera al abrir y se ve en la pestaña',
        (tester) async {
      await _pumpShell(tester, prepare: (env) {
        env.cliente.carrito.lineas
          ..add(arrozCliente.toLinea(3))
          ..add(lecheCliente.toLinea(1));
      });

      // Dos productos distintos (aunque sean cuatro unidades).
      expect(_insigniaDelCarrito(tester), 2);
    });

    testWidgets('el número cambia al agregar y al quitar productos',
        (tester) async {
      final (_, blocs) = await _pumpShell(tester);

      blocs!.carrito.add(CarritoProductoAgregado('p1'));
      await tester.pumpAndSettle();
      expect(_insigniaDelCarrito(tester), 1);

      blocs.carrito.add(CarritoProductoAgregado('p2'));
      await tester.pumpAndSettle();
      expect(_insigniaDelCarrito(tester), 2);

      blocs.carrito.add(CarritoProductoQuitado('p1'));
      await tester.pumpAndSettle();
      expect(_insigniaDelCarrito(tester), 1);
    });

    testWidgets('agregar el mismo producto no cambia el número de productos',
        (tester) async {
      final (_, blocs) = await _pumpShell(tester);

      blocs!.carrito.add(CarritoProductoAgregado('p1'));
      await tester.pumpAndSettle();
      blocs.carrito.add(CarritoProductoAgregado('p1'));
      await tester.pumpAndSettle();

      expect(_insigniaDelCarrito(tester), 1);
      expect(blocs.carrito.state.unidades, 2);
    });

    testWidgets('la pestaña Carrito abre el carrito', (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Carrito'));
      await tester.pumpAndSettle();

      expect(find.text('CARRITO'), findsOneWidget);
      expect(find.text('Pantalla aún no disponible'), findsNothing);
    });

    testWidgets('el número también se ve en la pestaña desde el Perfil',
        (tester) async {
      await _pumpShell(tester, prepare: (env) {
        env.cliente.carrito.lineas.add(arrozCliente.toLinea(1));
      });

      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(_insigniaDelCarrito(tester), 1);
    });
  });

  group('Home del cliente · explorar y favoritos', () {
    // La lupa y el buscador del Home son de la HU-12: abren la búsqueda real,
    // no la exploración provisional de esta historia.
    testWidgets('la lupa del encabezado abre la búsqueda (HU-12)',
        (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.widgetWithIcon(BotonCircular, Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('BUSQUEDA'), findsOneWidget);
      expect(find.text('EXPLORAR'), findsNothing);
    });

    testWidgets('buscar desde el buscador abre la búsqueda (HU-12)',
        (tester) async {
      await _pumpShell(tester);

      await tester.enterText(find.byType(TextField), 'arroz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('BUSQUEDA'), findsOneWidget);
      expect(find.text('EXPLORAR'), findsNothing);
    });

    testWidgets('"Comenzar ahora" abre la exploración', (tester) async {
      await _pumpShell(tester);

      final boton = find.text('Comenzar ahora');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.text('EXPLORAR'), findsOneWidget);
    });

    testWidgets('"Comparar" abre la búsqueda (HU-12), no la exploración',
        (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Comparar'));
      await tester.pumpAndSettle();

      expect(find.text('BUSQUEDA'), findsOneWidget);
      expect(find.text('EXPLORAR'), findsNothing);
    });

    testWidgets('"Mis favoritos" del Perfil abre los favoritos', (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mis favoritos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mis favoritos'));
      await tester.pumpAndSettle();

      expect(find.text('FAVORITOS'), findsOneWidget);
    });
  });

  group('RolShell sin el carrito del cliente (pruebas de navegación)', () {
    testWidgets('la pestaña Carrito sigue avisando que no está disponible',
        (tester) async {
      await _pumpShell(tester, conCliente: false);

      await tester.tap(find.text('Carrito'));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla aún no disponible'), findsOneWidget);
      expect(find.text('CARRITO'), findsNothing);
      expect(_insigniaDelCarrito(tester), isNull);
    });

    testWidgets('la lupa abre la búsqueda aunque no haya carrito',
        (tester) async {
      await _pumpShell(tester, conCliente: false);

      await tester.tap(find.widgetWithIcon(BotonCircular, Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('BUSQUEDA'), findsOneWidget);
      expect(find.text('EXPLORAR'), findsNothing);
    });
  });
}
