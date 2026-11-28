import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/comparacion/domain/comparador_carrito.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/pages/alternativa_detalle_page.dart';
import 'package:smartcart/features/comparacion/presentation/pages/comparacion_page.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/presentation/widgets/mapa_establecimientos.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/fakes_comparacion.dart';
import '../support/fakes_ubicacion.dart';
import '../support/pump_helpers.dart';

Future<TestEnv> _pumpComparacion(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
  double ancho = 420,
  void Function(RouteSettings ruta)? alNavegar,
}) async {
  setScreenSize(tester, ancho, 1600);
  final env = TestEnv()..iniciarSesionComoClienteConComercios();
  env.comparacion.lineas = carritoEjemplo();
  prepare?.call(env);
  final blocs = env.clienteBlocs();
  addTearDown(blocs.cerrar);
  final bloc = env.comparacionBloc()..add(ComparacionIniciada());
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        alNavegar?.call(settings);
        return stubRoutes(settings);
      },
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: blocs.carrito),
          BlocProvider.value(value: blocs.favoritos),
          BlocProvider.value(value: bloc),
        ],
        child: const ComparacionPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

void _conUbicacion(TestEnv env) => env.ubicacion.repositorio.guardada =
    const PreferenciaUbicacion(ubicacion: ubicacionCliente, radioM: 5000);

void main() {
  setUpAll(() => MapaEstablecimientos.cargarTeselas = false);
  tearDownAll(() => MapaEstablecimientos.cargarTeselas = true);

  group('ComparacionPage', () {
    testWidgets('escenario 1: muestra las alternativas con total, ahorro, '
        'comercios y distancia; el criterio elegido va primero',
        (tester) async {
      await _pumpComparacion(tester, prepare: _conUbicacion);

      expect(find.text('Mayor ahorro'), findsNWidgets(2)); // chip y tarjeta
      expect(find.text('Tu criterio'), findsOneWidget);
      expect(find.text('Ahorras \$ 2.200'), findsOneWidget);
      expect(find.text('\$ 29.900'), findsOneWidget);
      expect(find.text('11,7 km'), findsOneWidget);
      // Comodidad: un comercio y sin ahorro.
      expect(find.text('\$ 32.600'), findsOneWidget);
      // La alternativa del criterio elegido es la primera tarjeta.
      final ahorro = tester.getTopLeft(find.text('\$ 29.900'));
      final comodidad = tester.getTopLeft(find.text('\$ 32.600'));
      expect(ahorro.dy, lessThan(comodidad.dy));
    });

    testWidgets('escenario 2: al elegir Comodidad su tarjeta pasa primero',
        (tester) async {
      await _pumpComparacion(tester, prepare: _conUbicacion);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Comodidad'));
      await tester.pumpAndSettle();

      final comodidad = tester.getTopLeft(find.text('\$ 32.600'));
      final ahorro = tester.getTopLeft(find.text('\$ 29.900'));
      expect(comodidad.dy, lessThan(ahorro.dy));
    });

    testWidgets('escenario 4: con 5 km de distancia máxima cambia el total',
        (tester) async {
      await _pumpComparacion(tester, prepare: _conUbicacion);

      await tester.tap(find.widgetWithText(ChoiceChip, '5 km'));
      await tester.pumpAndSettle();

      // Sin C, el arroz se compra en B: 8.400 + 3.900 + 12.000 + 6.000.
      expect(find.text('\$ 30.300'), findsNWidgets(2)); // Ahorro y Calidad
      expect(find.text('\$ 29.900'), findsNothing);
    });

    testWidgets('escenario 5: avisa qué producto falta', (tester) async {
      await _pumpComparacion(tester, prepare: (env) {
        env.comparacion.lineas = [
          ...carritoEjemplo(),
          linea('miel', 'Miel de abejas', 1, []),
        ];
      });

      expect(find.textContaining('No encontramos disponible: Miel de abejas'),
          findsOneWidget);
      expect(find.text('Mayor ahorro'), findsWidgets);
    });

    testWidgets('escenario 6: con el carrito vacío invita a agregar productos',
        (tester) async {
      await _pumpComparacion(tester, prepare: (env) {
        env.comparacion.lineas = [];
      });

      expect(find.text('Tu carrito está vacío'), findsOneWidget);
      await tester.tap(find.text('Explorar productos'));
      await tester.pumpAndSettle();
      expect(find.text('EXPLORAR'), findsOneWidget);
    });

    testWidgets('sin ubicación ofrece configurarla y abre el mapa',
        (tester) async {
      await _pumpComparacion(tester);

      expect(find.text('No disponible'), findsNWidgets(3));
      await tester.tap(find.text('Configurar ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('MAPA'), findsOneWidget);
    });

    testWidgets('"Ver detalle" abre el detalle con la alternativa',
        (tester) async {
      RouteSettings? abierta;
      await _pumpComparacion(tester, alNavegar: (r) => abierta = r);

      await tester.tap(find.text('Ver detalle ›').first);
      await tester.pumpAndSettle();

      expect(abierta?.name, AppRoutes.comparacionDetalle);
      final args = abierta?.arguments as AlternativaArgs;
      expect(args.alternativa.criterio, CriterioCompra.ahorro);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await _pumpComparacion(tester, ancho: 320, prepare: _conUbicacion);

      expect(tester.takeException(), isNull);
    });
  });

  group('AlternativaDetallePage', () {
    Future<void> pumpDetalle(WidgetTester tester, {double ancho = 420}) async {
      setScreenSize(tester, ancho, 2400);
      final carrito = [
        ...carritoEjemplo(),
      ];
      carrito[1] = linea('leche-a', 'Leche 1 L', 1, [
        oferta('leche-a', 'A', 4100),
        oferta('leche-b', 'B', 3900,
            fuente: FuentePrecio.colaborador,
            enPromocion: true,
            precioNormal: 4500),
      ]);
      final r = ComparadorCarrito.comparar(
          lineas: carrito, cliente: ubicacionCliente);
      await tester.pumpWidget(MaterialApp(
        home: AlternativaDetallePage(
          args: AlternativaArgs(
            alternativa: r.alternativas[CriterioCompra.ahorro]!,
            cliente: ubicacionCliente,
          ),
          reloj: () => ahoraComparacion,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra los productos por comercio con su precio, fuente, '
        'fecha, confianza y la calificación del comercio', (tester) async {
      await pumpDetalle(tester);

      expect(find.byType(MapaEstablecimientos), findsOneWidget);
      expect(find.text('Tienda B'), findsOneWidget);
      expect(find.textContaining('★ 5,0 (10)'), findsOneWidget);
      expect(find.textContaining('Sin calificaciones'), findsOneWidget); // C
      expect(find.text('Fuente: Comunidad'), findsOneWidget);
      expect(find.text('Fuente: Comercio'), findsNWidgets(3));
      expect(find.text('Antes \$ 4.500'), findsOneWidget);
      expect(find.text('Confianza alta'), findsNWidgets(3));
      expect(find.text('Confianza media'), findsOneWidget);
      expect(find.text('Cantidad: 3'), findsOneWidget);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await pumpDetalle(tester, ancho: 320);

      expect(tester.takeException(), isNull);
    });

    testWidgets('sin el carrito del cliente no se ofrece elegirla',
        (tester) async {
      await pumpDetalle(tester);

      expect(find.text('Elegir esta alternativa'), findsNothing);
    });

    testWidgets('HU-20: "Elegir esta alternativa" lleva a confirmar con sus '
        'productos', (tester) async {
      setScreenSize(tester, 420, 2400);
      final env = TestEnv()..iniciarSesionComoClienteConComercios();
      final blocs = env.clienteBlocs();
      addTearDown(blocs.cerrar);
      RouteSettings? abierta;
      final r = ComparadorCarrito.comparar(lineas: carritoEjemplo());
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          abierta = settings;
          return stubRoutes(settings);
        },
        home: AlternativaDetallePage(
          args: AlternativaArgs(
            alternativa: r.alternativas[CriterioCompra.ahorro]!,
            blocs: blocs,
          ),
          reloj: () => ahoraComparacion,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Elegir esta alternativa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir esta alternativa'));
      await tester.pumpAndSettle();

      expect(abierta?.name, AppRoutes.confirmarCompra);
      final args = abierta?.arguments as ConBlocsDelCliente;
      final seleccion = args.argumento as SeleccionCompra;
      expect(seleccion.lineas.map((l) => l.idProducto),
          unorderedEquals(['arroz-c', 'leche-b', 'cafe-b', 'pan-a']));
      expect(seleccion.productosDelCarrito,
          unorderedEquals(['arroz-a', 'leche-a', 'cafe-b', 'pan-a']));
    });
  });
}
