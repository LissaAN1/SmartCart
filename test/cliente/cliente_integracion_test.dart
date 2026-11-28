import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_routes.dart';
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
  void Function(RouteSettings ruta)? alNavegar,
}) async {
  setScreenSize(tester, 420, 1000);
  final env = TestEnv()..iniciarSesionComoCliente();
  prepare?.call(env);
  ClienteBlocs? blocs;

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        alNavegar?.call(settings);
        return stubRoutes(settings);
      },
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

    // HU-13: la búsqueda recibe el carrito y los favoritos, para poder agregar
    // y guardar desde el detalle de un producto.
    testWidgets('la lupa lleva a la búsqueda el carrito y los favoritos',
        (tester) async {
      RouteSettings? abierta;
      final (_, blocs) =
          await _pumpShell(tester, alNavegar: (r) => abierta = r);

      await tester.tap(find.widgetWithIcon(BotonCircular, Icons.search));
      await tester.pumpAndSettle();

      expect(abierta?.name, AppRoutes.busqueda);
      final args = abierta?.arguments;
      expect(args, isA<ConBlocsDelCliente>());
      expect((args as ConBlocsDelCliente).argumento, '');
      expect(args.blocs.carrito, same(blocs!.carrito));
      expect(args.blocs.favoritos, same(blocs.favoritos));
    });

    testWidgets('el buscador lleva lo escrito junto con los blocs',
        (tester) async {
      RouteSettings? abierta;
      await _pumpShell(tester, alNavegar: (r) => abierta = r);

      await tester.enterText(find.byType(TextField), 'arroz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final args = abierta?.arguments as ConBlocsDelCliente;
      expect(args.argumento, 'arroz');
    });

    testWidgets('sin el carrito del cliente la búsqueda se abre solo con el '
        'texto, como antes', (tester) async {
      RouteSettings? abierta;
      await _pumpShell(tester,
          conCliente: false, alNavegar: (r) => abierta = r);

      await tester.tap(find.widgetWithIcon(BotonCircular, Icons.search));
      await tester.pumpAndSettle();

      expect(abierta?.name, AppRoutes.busqueda);
      expect(abierta?.arguments, '');
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

    testWidgets('HU-18: "Comparar" abre la comparación del carrito',
        (tester) async {
      RouteSettings? abierta;
      await _pumpShell(tester, alNavegar: (r) => abierta = r);

      await tester.tap(find.text('Comparar'));
      await tester.pumpAndSettle();

      expect(find.text('COMPARACION'), findsOneWidget);
      expect(abierta?.arguments, isA<ClienteBlocs>());
      expect(find.text('BUSQUEDA'), findsNothing);
    });

    testWidgets('HU-19: el botón de ubicación del Home abre el mapa',
        (tester) async {
      await _pumpShell(tester);

      await tester.tap(find.byIcon(Icons.place_outlined));
      await tester.pumpAndSettle();

      expect(find.text('MAPA'), findsOneWidget);
    });

    testWidgets('HU-19: "Mi ubicación" del Perfil abre el mapa',
        (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Mi ubicación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('MAPA'), findsOneWidget);
    });

    testWidgets('"Historial de compras" del Perfil abre Mis órdenes (HU-20)',
        (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Historial de compras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Historial de compras'));
      await tester.pumpAndSettle();

      expect(find.text('MIS ORDENES'), findsOneWidget);
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
