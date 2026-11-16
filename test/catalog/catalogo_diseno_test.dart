import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/catalog/presentation/pages/catalogo_page.dart';
import 'package:smartcart/features/catalog/presentation/pages/producto_form_page.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Productos del diseño: uno con stock normal, uno con stock bajo y uno
/// agotado y sin precio.
void _sembrar(TestEnv env) {
  env.catalogo.deComercio('c1').addAll(const [
    Producto(
      id: 'p1',
      nombre: 'Arroz Premium (1kg)',
      idCategoria: 'cat-super',
      categoria: 'Super',
      precio: 4500,
      stock: 45,
    ),
    Producto(
      id: 'p2',
      nombre: 'Leche Entera (1L)',
      idCategoria: 'cat-lacteos',
      categoria: 'Lácteos',
      precio: 3800,
      stock: 8,
    ),
    Producto(
      id: 'p3',
      nombre: 'Canasta de Frutas',
      idCategoria: 'cat-frutas',
      categoria: 'Frutas',
      disponible: false,
      stock: 12,
    ),
  ]);
  env.precios
    ..precargar('p1', 4500)
    ..precargar('p2', 3800);
}

Future<TestEnv> _pumpCatalogo(WidgetTester tester, {double ancho = 420}) async {
  setScreenSize(tester, ancho, 1000);
  final env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  _sembrar(env);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        if (settings.name == AppRoutes.catalogoProducto && args is Producto) {
          return MaterialPageRoute<bool>(
            settings: settings,
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => env.productoFormBloc(editando: args)
                    ..add(ProductoFormStarted()),
                ),
                BlocProvider(
                  create: (_) =>
                      env.precioBloc(args)..add(PrecioProductoStarted()),
                ),
              ],
              child: ProductoFormPage(producto: args, ahora: () => env.ahora),
            ),
          );
        }
        return null;
      },
      home: MultiBlocProvider(
        providers: [
          BlocProvider<PaginatedBloc<Producto>>(
            create: (_) => env.productosBloc()..add(PaginatedStarted()),
          ),
          BlocProvider(
            create: (_) => env.inventarioBloc()..add(InventarioStarted()),
          ),
        ],
        child: const CatalogoPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

const _arroz = Producto(
  id: 'p1',
  nombre: 'Arroz Diana Premium 5kg',
  codigoBarras: '8402119932',
  idCategoria: 'cat-super',
  categoria: 'Super',
  precio: 4900,
  stock: 30,
);

Future<TestEnv> _pumpEditar(
  WidgetTester tester, {
  double ancho = 420,
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, ancho, 1000);
  final env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  env.catalogo.deComercio('c1').add(_arroz);
  env.precios.precargar('p1', 4900);
  // Historial: 5.200 desde septiembre y 4.900 desde este mes.
  env.precios.historiales['p1'] = [
    RegistroPrecio(
      precio: 5200,
      disponible: true,
      fuente: FuentePrecio.comercio,
      registradoEn: DateTime(2026, 9, 5),
    ),
    RegistroPrecio(
      precio: 4900,
      disponible: true,
      fuente: FuentePrecio.comercio,
      registradoEn: DateTime(2026, 11, 3),
    ),
  ];
  prepare?.call(env);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                env.productoFormBloc(editando: _arroz)..add(ProductoFormStarted()),
          ),
          BlocProvider(
            create: (_) => env.precioBloc(_arroz)..add(PrecioProductoStarted()),
          ),
        ],
        child: ProductoFormPage(producto: _arroz, ahora: () => env.ahora),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _verAbajo(WidgetTester tester, Finder finder) async {
  // Editar Producto construye todos sus campos (SingleChildScrollView), así
  // que basta con llevar el widget a la vista. Antes se quita el foco (como
  // al cerrar el teclado): si no, el campo enfocado vuelve a mover la vista.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _verArribaHasta(WidgetTester tester, Finder finder) async {
  // Editar Producto construye todos sus campos (SingleChildScrollView), así
  // que basta con llevar el widget a la vista. Antes se quita el foco (como
  // al cerrar el teclado): si no, el campo enfocado vuelve a mover la vista.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Finder _campo(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    );

void main() {
  group('Catálogo con el diseño', () {
    testWidgets('muestra buscador, chips y el resumen del inventario',
        (tester) async {
      await _pumpCatalogo(tester);

      expect(find.text('Catálogo'), findsOneWidget);
      expect(find.text('Buscar productos...'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Lácteos'), findsWidgets);
      expect(find.text('TOTAL ITEMS'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // 4.500 × 45 + 3.800 × 8 = 232.900.
      expect(find.text(r'$232.9k'), findsOneWidget);
      // Leche (8 uds) es la única con stock bajo.
      expect(find.text('BAJO STOCK'), findsOneWidget);
      expect(find.text('Inventario Activo'), findsOneWidget);
      expect(find.text('3 productos'), findsOneWidget);
    });

    testWidgets('cada tarjeta muestra precio, stock y ACTIVO/INACTIVO',
        (tester) async {
      await _pumpCatalogo(tester);

      expect(find.text(r'$ 4.500'), findsOneWidget);
      expect(find.text('Stock: 45 uds'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      expect(find.text('Stock: 8 uds'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('ACTIVO'), findsNWidgets(2));
      await tester.scrollUntilVisible(find.text('INACTIVO'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('INACTIVO'), findsOneWidget);
      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('Sin precio'), findsOneWidget);
    });

    testWidgets('la tarjeta no tiene interruptor ni menú: abre Editar Producto',
        (tester) async {
      await _pumpCatalogo(tester);

      expect(find.byType(Switch), findsNothing);
      expect(find.byTooltip('Más opciones'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('buscar filtra la lista', (tester) async {
      await _pumpCatalogo(tester);

      await tester.enterText(find.byKey(const Key('buscador-catalogo')), 'leche');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Leche Entera (1L)'), findsOneWidget);
      expect(find.text('Arroz Premium (1kg)'), findsNothing);
    });

    testWidgets('una búsqueda sin resultados lo dice', (tester) async {
      await _pumpCatalogo(tester);

      await tester.enterText(find.byKey(const Key('buscador-catalogo')), 'xyz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No encontramos productos con ese filtro.'), findsOneWidget);
    });

    testWidgets('un chip filtra por categoría y "Todos" lo quita',
        (tester) async {
      await _pumpCatalogo(tester);

      await tester.tap(find.text('Frutas').first);
      await tester.pumpAndSettle();
      expect(find.text('Canasta de Frutas'), findsOneWidget);
      expect(find.text('Arroz Premium (1kg)'), findsNothing);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Arroz Premium (1kg)'), findsOneWidget);
    });

    testWidgets('tocar una tarjeta abre Editar Producto', (tester) async {
      await _pumpCatalogo(tester);

      await tester.tap(find.text('Arroz Premium (1kg)'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Producto'), findsOneWidget);
      expect(find.text('Historial de Precios'), findsOneWidget);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await _pumpCatalogo(tester, ancho: 320);

      expect(tester.takeException(), isNull);
      expect(find.text('Inventario Activo'), findsOneWidget);
    });
  });

  group('Editar Producto con el diseño', () {
    testWidgets('muestra foto, nombre, SKU, tienda e historial',
        (tester) async {
      await _pumpEditar(tester);

      expect(find.byTooltip('Cambiar foto'), findsOneWidget);
      expect(find.text('Arroz Diana Premium 5kg'), findsWidgets);
      expect(find.text('SKU: 8402119932'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Historial de Precios'), findsOneWidget);
      expect(find.text('Últimos 4 meses'), findsOneWidget);
      // 5.200 al empezar noviembre → 4.900: bajó 5,8 %.
      expect(find.text('Bajó un 5.8% este mes'), findsOneWidget);
      expect(find.text('VARIACIÓN REAL'), findsOneWidget);
    });

    testWidgets('el precio actual muestra su variación', (tester) async {
      await _pumpEditar(tester);
      await _verAbajo(tester, find.byKey(const Key('campo-precio')));

      expect(find.text('PRECIO ACTUAL (COP)'), findsOneWidget);
      expect(find.text('4.900'), findsOneWidget);
      expect(find.text('-6%'), findsOneWidget);
    });

    testWidgets('tienda y aviso de la HU-11', (tester) async {
      await _pumpEditar(tester);
      await _verAbajo(tester, find.textContaining('se publica de inmediato'));

      expect(find.text('TIENDA / SUCURSAL'), findsOneWidget);
      expect(find.text('Minimercado La Esquina · Cali, San Fernando'),
          findsOneWidget);
      expect(
        find.text('El nuevo precio se publica de inmediato con la fuente '
            'Comercio y queda guardado en el historial.'),
        findsOneWidget,
      );
    });

    testWidgets('Guardar Cambios guarda el precio nuevo y el stock',
        (tester) async {
      final env = await _pumpEditar(tester);

      await _verAbajo(tester, _campo('campo-precio'));
      await tester.enterText(_campo('campo-precio'), '4.600');
      await _verAbajo(tester, _campo('campo-stock'));
      await tester.enterText(_campo('campo-stock'), '12');
      final guardar = find.widgetWithText(FilledButton, 'Guardar Cambios');
      await _verAbajo(tester, guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(env.precios.precios['p1']?.precio, 4600);
      expect(env.catalogo.deComercio('c1').single.stock, 12);
    });

    testWidgets('la foto elegida se ve y se sube al guardar', (tester) async {
      final env = await _pumpEditar(tester, prepare: (env) {
        env.selectorImagen.foto =
            ImagenProducto(bytes: _pngTransparente, extension: 'png');
      });

      await tester.tap(find.byTooltip('Cambiar foto'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsWidgets);

      final guardar = find.widgetWithText(FilledButton, 'Guardar Cambios');
      await _verAbajo(tester, guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(env.catalogo.fotosSubidas.single.idProducto, 'p1');
    });

    testWidgets('escenario 2: marcar agotado y Guardar Cambios',
        (tester) async {
      final env = await _pumpEditar(tester);
      await _verAbajo(tester, find.byType(Switch));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('Los clientes lo verán como no disponible'),
          findsOneWidget);
      // Todavía no se guarda: se guarda con el botón.
      expect(env.precios.precios['p1']?.disponible, isTrue);

      final guardar = find.widgetWithText(FilledButton, 'Guardar Cambios');
      await _verAbajo(tester, guardar);
      await tester.tap(guardar);
      await tester.pumpAndSettle();

      expect(env.precios.precios['p1']?.disponible, isFalse);
    });

    testWidgets('sin precio el interruptor espera a que se escriba uno',
        (tester) async {
      await _pumpEditar(tester);
      await _verAbajo(tester, _campo('campo-precio'));
      await tester.enterText(_campo('campo-precio'), '');
      await tester.pump();
      await _verAbajo(tester, find.byType(Switch));

      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(find.text('Escribe el precio para poder marcarlo como agotado'),
          findsOneWidget);

      await _verArribaHasta(tester, _campo('campo-precio'));
      await tester.enterText(_campo('campo-precio'), '5.000');
      await tester.pump();
      await _verAbajo(tester, find.byType(Switch));
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    });

    testWidgets('escenario 3: una promoción vencida aparece como vencida',
        (tester) async {
      await _pumpEditar(tester, prepare: (env) {
        env.precios.promociones['p1'] = Promocion(
          idProducto: 'p1',
          precioPromocional: 4000,
          inicio: DateTime(2026, 11, 1),
          fin: DateTime(2026, 11, 10),
        );
      });
      await _verAbajo(tester, find.text('Vencida'));

      expect(find.text('Vencida'), findsOneWidget);
      expect(find.text('Elegir fechas de inicio y fin'), findsOneWidget);
    });

    testWidgets('eliminar avisa que se borra el historial', (tester) async {
      await _pumpEditar(tester);
      await _verAbajo(
        tester,
        find.text('ESTA ACCIÓN NO SE PUEDE DESHACER Y BORRARÁ EL HISTORIAL'),
      );

      expect(find.text('Eliminar producto'), findsOneWidget);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await _pumpEditar(tester, ancho: 320);
      expect(tester.takeException(), isNull);

      final guardar = find.widgetWithText(FilledButton, 'Guardar Cambios');
      await _verAbajo(tester, guardar);
      expect(tester.takeException(), isNull);
    });
  });
}

/// PNG de 1×1 transparente: basta para que `Image.memory` lo dibuje.
final _pngTransparente = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
