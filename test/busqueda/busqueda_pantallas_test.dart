import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/pages/busqueda_page.dart';
import 'package:smartcart/features/busqueda/presentation/pages/detalle_producto_page.dart';
import 'package:smartcart/features/cliente/presentation/pages/cliente_home_screen.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';
import 'busqueda_datos.dart';

/// Monta la búsqueda con las mismas rutas que arma `AppRouter`. [escaneado]
/// es lo que "lee" la cámara.
Future<TestEnv> _pumpBusqueda(
  WidgetTester tester, {
  String texto = '',
  String? escaneado,
  double ancho = 420,
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, ancho, 900);
  final env = entornoBusqueda();
  prepare?.call(env);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        if (settings.name == AppRoutes.busquedaDetalle &&
            args is ConsultaProducto) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => BlocProvider(
              create: (_) =>
                  env.detalleBloc(args)..add(DetalleProductoStarted()),
              child: const DetalleProductoPage(),
            ),
          );
        }
        return null;
      },
      home: BlocProvider<PaginatedBloc<ResultadoBusqueda>>(
        create: (_) => env.busquedaBloc(texto: texto)..add(PaginatedStarted()),
        child: BusquedaPage(
          textoInicial: texto,
          escanear: (_) async => escaneado,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byKey(const Key('buscador-productos')), texto);
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pumpAndSettle();
}

void main() {
  group('Búsqueda', () {
    testWidgets('sin texto explica qué hacer', (tester) async {
      await _pumpBusqueda(tester);

      expect(find.text('Buscar productos'), findsOneWidget);
      expect(find.textContaining('Escribe el nombre o la marca'), findsOneWidget);
      expect(find.text('Escanear código de barras'), findsOneWidget);
    });

    testWidgets(
        'escenario 1: escribir "arroz" muestra el producto con su rango',
        (tester) async {
      await _pumpBusqueda(tester);

      await _escribir(tester, 'arroz');

      expect(find.text('Arroz Diana 500 g'), findsOneWidget);
      expect(find.text(r'$ 4.200 – $ 5.000'), findsOneWidget);
      expect(find.text('En 2 establecimientos'), findsOneWidget);
      expect(find.text('Leche entera 1L'), findsNothing);
    });

    testWidgets('llega con el texto del Home y ya muestra resultados',
        (tester) async {
      await _pumpBusqueda(tester, texto: 'leche');

      expect(find.text('Leche entera 1L'), findsOneWidget);
      // Un solo precio: sin rango.
      expect(find.text(r'$ 3.800'), findsOneWidget);
      expect(find.text('En 1 establecimiento'), findsOneWidget);
    });

    testWidgets('un producto agotado en todos se muestra como agotado',
        (tester) async {
      await _pumpBusqueda(tester);

      await _escribir(tester, 'lenteja');

      expect(find.text('Lenteja'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('escenario 3: sin resultados muestra "No encontramos productos"',
        (tester) async {
      await _pumpBusqueda(tester);

      await _escribir(tester, 'zzz');

      expect(find.text('No encontramos productos'), findsOneWidget);
    });

    testWidgets('carga más resultados al bajar', (tester) async {
      await _pumpBusqueda(tester, prepare: (env) {
        env.busqueda.resultados
          ..clear()
          ..addAll([
            for (var i = 1; i <= 30; i++)
              ResultadoBusqueda(
                clave: 'k$i',
                nombre: 'Arroz $i',
                categoria: 'Super',
                precioMin: 1000 + i,
                precioMax: 1000 + i,
                establecimientos: 1,
              ),
          ]);
      });
      await _escribir(tester, 'arroz');
      expect(find.text('Arroz 30'), findsNothing);

      await tester.dragUntilVisible(
        find.text('Arroz 30'),
        find.byType(ListView).first,
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(find.text('Arroz 30'), findsOneWidget);
    });

    testWidgets('tocar un resultado abre el producto con sus precios',
        (tester) async {
      await _pumpBusqueda(tester, texto: 'arroz');

      await tester.tap(find.text('Arroz Diana 500 g'));
      await tester.pumpAndSettle();

      expect(find.text('Precios del producto'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Tienda Don Pepe'), findsOneWidget);
    });

    testWidgets('escenario 2: escanear un código abre ese producto',
        (tester) async {
      final env = await _pumpBusqueda(tester, escaneado: '7701234567890');

      await tester.tap(find.byTooltip('Escanear código de barras'));
      await tester.pumpAndSettle();

      expect(find.text('Precios del producto'), findsOneWidget);
      expect(find.text('Arroz Diana 500 g'), findsOneWidget);
      expect(env.busqueda.clavesPedidas.single, 'cb:7701234567890');
    });

    testWidgets('un código que nadie vende lo dice y deja reintentar',
        (tester) async {
      await _pumpBusqueda(tester, escaneado: '7709999999999');

      await tester.tap(find.text('Escanear código de barras'));
      await tester.pumpAndSettle();

      expect(
        find.text('No encontramos productos con el código 7709999999999.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('cancelar el escáner no abre nada', (tester) async {
      await _pumpBusqueda(tester);

      await tester.tap(find.text('Escanear código de barras'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar productos'), findsOneWidget);
      expect(find.text('Precios del producto'), findsNothing);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await _pumpBusqueda(tester, texto: 'arroz', ancho: 320);

      expect(tester.takeException(), isNull);
      expect(find.text(r'$ 4.200 – $ 5.000'), findsOneWidget);
    });
  });

  group('Precios del producto', () {
    Future<void> abrirArroz(WidgetTester tester, {double ancho = 420}) async {
      await _pumpBusqueda(tester, texto: 'arroz', ancho: ancho);
      await tester.tap(find.text('Arroz Diana 500 g'));
      await tester.pumpAndSettle();
    }

    testWidgets('muestra el rango y cuántos establecimientos lo tienen',
        (tester) async {
      await abrirArroz(tester);

      expect(find.text(r'$ 4.200 – $ 5.000'), findsOneWidget);
      expect(find.text('En 2 establecimientos'), findsOneWidget);
      expect(find.text('Código 7701234567890'), findsOneWidget);
    });

    testWidgets('el más barato va primero, con su promoción', (tester) async {
      await abrirArroz(tester);

      expect(find.text('Mejor precio'), findsOneWidget);
      expect(find.text('Promoción'), findsOneWidget);
      final tachado = tester.widget<Text>(find.text(r'$ 5.000').first);
      expect(tachado.style?.decoration, TextDecoration.lineThrough);
      expect(find.textContaining('Fuente: Comercio'), findsNWidgets(3));
    });

    testWidgets('una tienda agotada se ve como no disponible', (tester) async {
      await abrirArroz(tester);
      await tester.scrollUntilVisible(find.text('Fruver El Centro'), 200,
          scrollable: find.byType(Scrollable).first);

      expect(find.text('Agotado'), findsOneWidget);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await abrirArroz(tester, ancho: 320);

      expect(tester.takeException(), isNull);
    });
  });

  group('Home del cliente', () {
    Future<List<RouteSettings>> pumpHome(WidgetTester tester) async {
      setScreenSize(tester, 420, 900);
      final abiertas = <RouteSettings>[];
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            abiertas.add(settings);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('BUSQUEDA')),
            );
          },
          home: const ClienteHomeScreen(nombre: 'Ana'),
        ),
      );
      await tester.pumpAndSettle();
      return abiertas;
    }

    testWidgets('la lupa abre la búsqueda', (tester) async {
      final abiertas = await pumpHome(tester);

      await tester.tap(find.widgetWithIcon(BotonCircular, Icons.search));
      await tester.pumpAndSettle();

      expect(abiertas.last.name, AppRoutes.busqueda);
      expect(find.text('BUSQUEDA'), findsOneWidget);
    });

    testWidgets('el buscador del Home envía lo escrito', (tester) async {
      final abiertas = await pumpHome(tester);

      await tester.enterText(find.byType(TextField).first, '  arroz ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(abiertas.last.name, AppRoutes.busqueda);
      expect(abiertas.last.arguments, 'arroz');
    });
  });
}
