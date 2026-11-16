import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/presentation/pages/catalogo_page.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/prices/presentation/pages/precio_producto_page.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

const _arroz = Producto(
  id: 'p1',
  nombre: 'Arroz blanco 500 g',
  idCategoria: 'cat-super',
  categoria: 'Super',
);

Future<TestEnv> _pumpPagina(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, 420, 1400);
  final env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  prepare?.call(env);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => env.precioBloc(_arroz)..add(PrecioProductoStarted()),
        child: PrecioProductoPage(ahora: () => env.ahora),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  final boton = find.text(texto);
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Finder _campo(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    );

void main() {
  group('PrecioProductoPage', () {
    testWidgets('escenario 1: registra el precio y muestra fecha y fuente',
        (tester) async {
      await _pumpPagina(tester);
      expect(find.textContaining('Aún no tiene precio'), findsOneWidget);

      await tester.enterText(_campo('campo-precio'), '2.500');
      await _tocar(tester, 'Guardar precio');

      expect(find.text(r'$ 2.500'), findsWidgets);
      expect(find.textContaining('Fuente: Comercio'), findsOneWidget);
      expect(find.textContaining('15 nov 2026 · 14:05'), findsWidgets);
      expect(find.text('Precio actualizado'), findsOneWidget);
    });

    testWidgets('un precio en cero no se envía', (tester) async {
      final env = await _pumpPagina(tester);

      await tester.enterText(_campo('campo-precio'), '0');
      await _tocar(tester, 'Guardar precio');

      expect(find.text('El precio debe ser mayor a cero'), findsOneWidget);
      expect(env.precios.guardados, isEmpty);
    });

    testWidgets('sin precio, el interruptor de disponibilidad está apagado',
        (tester) async {
      await _pumpPagina(tester);

      final interruptor = tester.widget<Switch>(find.byType(Switch));
      expect(interruptor.onChanged, isNull);
      expect(
        find.text('Guarda el precio para marcar la disponibilidad'),
        findsOneWidget,
      );
    });

    testWidgets('escenario 2: marcar el producto como agotado',
        (tester) async {
      final env = await _pumpPagina(
        tester,
        prepare: (env) => env.precios.precargar('p1', 2500),
      );
      expect(find.text('2.500'), findsOneWidget);

      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(env.precios.precios['p1']!.disponible, isFalse);
      expect(find.text('Los clientes lo ven como no disponible'), findsOneWidget);
      expect(find.text('Agotado'), findsWidgets);
    });

    testWidgets('con la promoción vigente muestra el precio promocional',
        (tester) async {
      await _pumpPagina(tester, prepare: (env) {
        env.precios.precargar('p1', 2500);
        env.precios.promociones['p1'] = Promocion(
          idProducto: 'p1',
          precioPromocional: 2000,
          inicio: DateTime(2026, 11, 10),
          fin: DateTime(2026, 11, 20),
        );
      });

      expect(find.text(r'$ 2.000'), findsWidgets);
      expect(find.text('En promoción'), findsOneWidget);
      expect(find.text('Vigente'), findsOneWidget);
      final tachado = tester.widget<Text>(find.text(r'$ 2.500'));
      expect(tachado.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('escenario 3: con la promoción vencida se ve el precio normal',
        (tester) async {
      await _pumpPagina(tester, prepare: (env) {
        env.precios.precargar('p1', 2500);
        env.precios.promociones['p1'] = Promocion(
          idProducto: 'p1',
          precioPromocional: 2000,
          inicio: DateTime(2026, 11, 1),
          fin: DateTime(2026, 11, 10),
        );
      });

      expect(find.text(r'$ 2.500'), findsOneWidget);
      expect(find.text('En promoción'), findsNothing);
      expect(find.text('Vencida'), findsOneWidget);
      // Los campos no se llenan con una promoción que ya terminó.
      expect(find.text('Elegir fechas de inicio y fin'), findsOneWidget);
    });

    testWidgets('sin fechas la promoción no se guarda', (tester) async {
      final env = await _pumpPagina(
        tester,
        prepare: (env) => env.precios.precargar('p1', 2500),
      );

      await tester.enterText(_campo('campo-promocion'), '2.000');
      await _tocar(tester, 'Guardar promoción');

      expect(find.text('Elige la fecha de inicio y la de fin'), findsOneWidget);
      expect(env.precios.promociones, isEmpty);
    });

    testWidgets('la promoción debe costar menos que el precio normal',
        (tester) async {
      await _pumpPagina(
        tester,
        prepare: (env) => env.precios.precargar('p1', 2500),
      );

      await tester.enterText(_campo('campo-promocion'), '3.000');
      await _tocar(tester, 'Guardar promoción');

      expect(find.textContaining('menos que el precio normal'), findsOneWidget);
    });

    testWidgets('cambia una promoción programada y luego la quita',
        (tester) async {
      final env = await _pumpPagina(tester, prepare: (env) {
        env.precios.precargar('p1', 2500);
        env.precios.promociones['p1'] = Promocion(
          idProducto: 'p1',
          precioPromocional: 2200,
          inicio: DateTime(2026, 11, 20),
          fin: DateTime(2026, 11, 25),
        );
      });
      expect(find.text('Programada'), findsOneWidget);
      expect(find.text('20 nov 2026 – 25 nov 2026'), findsOneWidget);

      await tester.enterText(_campo('campo-promocion'), '1.900');
      await _tocar(tester, 'Guardar promoción');
      expect(env.precios.promociones['p1']!.precioPromocional, 1900);
      expect(find.text('Promoción guardada'), findsOneWidget);

      await _tocar(tester, 'Quitar promoción');
      expect(env.precios.promociones, isEmpty);
      expect(find.text('Quitar promoción'), findsNothing);
    });

    testWidgets('muestra los últimos cambios del historial', (tester) async {
      await _pumpPagina(tester);

      await tester.enterText(_campo('campo-precio'), '2500');
      await _tocar(tester, 'Guardar precio');
      await tester.enterText(_campo('campo-precio'), '2800');
      await _tocar(tester, 'Guardar precio');

      expect(find.text('Todavía no hay cambios de precio.'), findsNothing);
      expect(find.byIcon(Icons.history), findsNWidgets(2));
    });
  });

  group('HU-11 desde el catálogo', () {
    Future<TestEnv> pumpCatalogo(WidgetTester tester) async {
      setScreenSize(tester, 420, 900);
      final env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
      env.catalogo.deComercio('c1').addAll(const [
        Producto(
          id: 'p1',
          nombre: 'Arroz blanco 500 g',
          idCategoria: 'cat-super',
          categoria: 'Super',
          precio: 2500,
          disponible: false,
        ),
        Producto(
          id: 'p2',
          nombre: 'Leche entera',
          idCategoria: 'cat-super',
          categoria: 'Super',
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            final args = settings.arguments;
            if (settings.name == AppRoutes.catalogoPrecio && args is Producto) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => BlocProvider(
                  create: (_) =>
                      env.precioBloc(args)..add(PrecioProductoStarted()),
                  child: PrecioProductoPage(ahora: () => env.ahora),
                ),
              );
            }
            return null;
          },
          home: BlocProvider(
            create: (_) => env.productosBloc()..add(PaginatedStarted()),
            child: const CatalogoPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('cada producto muestra su precio o "Sin precio"',
        (tester) async {
      await pumpCatalogo(tester);

      expect(find.text(r'$ 2.500'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('Sin precio'), findsOneWidget);
    });

    testWidgets('el botón de precio abre la edición rápida del producto',
        (tester) async {
      await pumpCatalogo(tester);

      await tester.tap(find.byTooltip('Precio y disponibilidad').last);
      await tester.pumpAndSettle();

      expect(find.text('Precio y disponibilidad'), findsOneWidget);
      expect(find.text('Leche entera'), findsOneWidget);
    });
  });
}
