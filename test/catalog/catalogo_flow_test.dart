import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/catalog/presentation/pages/catalogo_csv_page.dart';
import 'package:smartcart/features/catalog/presentation/pages/catalogo_page.dart';
import 'package:smartcart/features/catalog/presentation/pages/producto_form_page.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Monta el catálogo con las mismas rutas que arma `AppRouter`.
Future<TestEnv> _pumpCatalogo(
  WidgetTester tester, {
  ApprovalStatus estado = ApprovalStatus.aprobado,
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, 420, 900);
  final env = TestEnv()..iniciarSesionComoComercio(estado);
  prepare?.call(env);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        if (settings.name == AppRoutes.catalogoProducto) {
          final producto = args is Producto ? args : null;
          return MaterialPageRoute<bool>(
            settings: settings,
            builder: (_) => BlocProvider(
              create: (_) => env.productoFormBloc(editando: producto)
                ..add(ProductoFormStarted()),
              child: ProductoFormPage(producto: producto),
            ),
          );
        }
        if (settings.name == AppRoutes.catalogoCsv) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => BlocProvider(
              create: (_) => env.cargaCsvBloc(),
              child: const CatalogoCsvPage(),
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

/// El campo se identifica por la etiqueta que lleva arriba.
Future<void> _escribir(WidgetTester tester, String etiqueta, String texto) async {
  final input = find.descendant(
    of: find.ancestor(
      of: find.text(etiqueta),
      matching: find.byType(AuthTextField),
    ),
    matching: find.byType(TextFormField),
  );
  await tester.enterText(input, texto);
}

Future<void> _elegirCategoria(WidgetTester tester, String nombre) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nombre).last);
  await tester.pumpAndSettle();
}

Future<void> _tocarGuardar(WidgetTester tester) async {
  final boton = find.widgetWithText(FilledButton, 'Guardar');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  group('Lista del catálogo', () {
    testWidgets('muestra los productos del comercio con marca, categoría y código',
        (tester) async {
      await _pumpCatalogo(tester, prepare: (env) {
        env.catalogo.deComercio('c1').add(const Producto(
              id: 'p1',
              nombre: 'Arroz blanco 500 g',
              marca: 'Diana',
              codigoBarras: '7701234567890',
              idCategoria: 'cat-super',
              categoria: 'Super',
            ));
        env.catalogo.precargar('otro-comercio', 2);
      });

      expect(find.text('Mi catálogo'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Diana · Super'), findsOneWidget);
      expect(find.text('Código 7701234567890'), findsOneWidget);
      expect(find.text('Producto 1'), findsNothing);
    });

    testWidgets('sin productos invita a agregar el primero', (tester) async {
      await _pumpCatalogo(tester);

      expect(find.textContaining('Aún no tienes productos'), findsOneWidget);
    });

    testWidgets('escenario 2: un comercio pendiente debe esperar la aprobación',
        (tester) async {
      await _pumpCatalogo(tester, estado: ApprovalStatus.pendiente);

      expect(find.textContaining('pendiente de aprobación'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('si la carga falla deja reintentar', (tester) async {
      final env = await _pumpCatalogo(
        tester,
        prepare: (env) => env.catalogo.listError =
            const AuthFailure('No pudimos conectarnos.'),
      );
      expect(find.text('No pudimos conectarnos.'), findsOneWidget);

      env.catalogo.listError = null;
      env.catalogo.precargar('c1', 1);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Producto 1'), findsOneWidget);
    });

    testWidgets('carga más productos al llegar al final de la lista',
        (tester) async {
      await _pumpCatalogo(tester, prepare: (env) => env.catalogo.precargar('c1', 45));

      expect(find.text('Producto 1'), findsOneWidget);
      expect(find.text('Producto 45'), findsNothing);

      await tester.dragUntilVisible(
        find.text('Producto 45'),
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(find.text('Producto 45'), findsOneWidget);
    });
  });

  group('Formulario · escenario 1: crear un producto', () {
    testWidgets('el botón + abre el formulario con las categorías', (tester) async {
      await _pumpCatalogo(tester);

      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo producto'), findsOneWidget);
      expect(find.text('Eliminar producto'), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Frutas'), findsOneWidget);
      expect(find.text('Lácteos'), findsOneWidget);
    });

    testWidgets('sin completar lo obligatorio muestra los errores y no guarda',
        (tester) async {
      final env = await _pumpCatalogo(tester);
      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();

      await _tocarGuardar(tester);

      expect(find.text('Escribe el nombre del producto'), findsOneWidget);
      expect(find.text('Elige una categoría'), findsOneWidget);
      expect(env.catalogo.creados, isEmpty);
    });

    testWidgets('un código de barras inválido se avisa en el campo',
        (tester) async {
      final env = await _pumpCatalogo(tester);
      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();

      await _escribir(tester, 'Nombre del producto', 'Arroz blanco');
      await _escribir(tester, 'Código de barras (opcional)', '123');
      await _elegirCategoria(tester, 'Super');
      await _tocarGuardar(tester);

      expect(find.text('El código debe tener entre 8 y 14 dígitos'), findsOneWidget);
      expect(env.catalogo.creados, isEmpty);
    });

    testWidgets('completar el formulario agrega el producto al catálogo',
        (tester) async {
      final env = await _pumpCatalogo(tester);
      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();

      await _escribir(tester, 'Nombre del producto', 'Arroz blanco 500 g');
      await _escribir(tester, 'Marca (opcional)', 'Diana');
      await _escribir(tester, 'Código de barras (opcional)', '7701234567890');
      await _elegirCategoria(tester, 'Super');
      await _tocarGuardar(tester);

      // Vuelve a la lista y el producto ya aparece.
      expect(find.text('Mi catálogo'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Diana · Super'), findsOneWidget);
      expect(env.catalogo.creados.single.idComercio, 'c1');
    });

    testWidgets('si guardar falla muestra el mensaje y se queda en el formulario',
        (tester) async {
      await _pumpCatalogo(
        tester,
        prepare: (env) => env.catalogo.crearError =
            const AuthFailure('Ya tienes un producto con ese código de barras.'),
      );
      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();

      await _escribir(tester, 'Nombre del producto', 'Arroz blanco');
      await _elegirCategoria(tester, 'Super');
      await _tocarGuardar(tester);

      expect(find.text('Nuevo producto'), findsOneWidget);
      expect(
        find.text('Ya tienes un producto con ese código de barras.'),
        findsOneWidget,
      );
    });

    testWidgets('si las categorías no cargan permite reintentar', (tester) async {
      final env = await _pumpCatalogo(
        tester,
        prepare: (env) =>
            env.catalogo.categoriasError = const AuthFailure('Sin conexión.'),
      );
      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión.'), findsOneWidget);

      env.catalogo.categoriasError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Categoría'), findsOneWidget);
    });
  });

  group('Formulario · editar y eliminar', () {
    Future<TestEnv> abrirEdicion(WidgetTester tester) async {
      final env = await _pumpCatalogo(tester, prepare: (env) {
        env.catalogo.deComercio('c1').add(const Producto(
              id: 'p1',
              nombre: 'Arroz blanco 500 g',
              marca: 'Diana',
              codigoBarras: '7701234567890',
              idCategoria: 'cat-super',
              categoria: 'Super',
            ));
      });
      await tester.tap(find.text('Arroz blanco 500 g'));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('abre con los datos del producto', (tester) async {
      await abrirEdicion(tester);

      expect(find.text('Editar producto'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Diana'), findsOneWidget);
      // El campo también conserva su texto de ejemplo, por eso `findsWidgets`.
      expect(find.text('7701234567890'), findsWidgets);
      expect(find.text('Super'), findsOneWidget);
    });

    testWidgets('cambiar el nombre y guardar actualiza la lista', (tester) async {
      await abrirEdicion(tester);

      await _escribir(tester, 'Nombre del producto', 'Arroz integral 500 g');
      await _tocarGuardar(tester);

      expect(find.text('Mi catálogo'), findsOneWidget);
      expect(find.text('Arroz integral 500 g'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsNothing);
    });

    testWidgets('eliminar pide confirmación y quita el producto', (tester) async {
      final env = await abrirEdicion(tester);

      await tester.ensureVisible(find.text('Eliminar producto'));
      await tester.tap(find.text('Eliminar producto'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar Arroz blanco 500 g?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Mi catálogo'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsNothing);
      expect(env.catalogo.deComercio('c1'), isEmpty);
    });

    testWidgets('cancelar la confirmación no elimina nada', (tester) async {
      final env = await abrirEdicion(tester);

      await tester.ensureVisible(find.text('Eliminar producto'));
      await tester.tap(find.text('Eliminar producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar producto'), findsOneWidget);
      expect(env.catalogo.deComercio('c1').length, 1);
    });
  });

  group('Carga por archivo · escenario 3', () {
    Future<void> abrirCsv(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Cargar por archivo'));
      await tester.pumpAndSettle();
    }

    testWidgets('explica el formato esperado', (tester) async {
      await _pumpCatalogo(tester);
      await abrirCsv(tester);

      expect(find.text('Cargar por archivo'), findsOneWidget);
      expect(find.text('Cómo debe ser el archivo'), findsOneWidget);
      expect(find.text('Elegir archivo CSV'), findsOneWidget);
    });

    testWidgets('carga las filas válidas y muestra cuáles fallaron y por qué',
        (tester) async {
      final env = await _pumpCatalogo(tester);
      env.selectorCsv.archivo = const ArchivoCsv(
        nombre: 'productos.csv',
        contenido: 'nombre,marca,codigo_barras,categoria\n'
            'Arroz blanco,Diana,7701234567890,Super\n'
            'ab,,,Super\n'
            'Queso campesino,,,Charcutería\n',
      );
      await abrirCsv(tester);

      await tester.tap(find.text('Elegir archivo CSV'));
      await tester.pumpAndSettle();

      expect(find.text('productos.csv'), findsOneWidget);
      expect(find.text('Se cargó 1 producto.'), findsOneWidget);
      expect(find.text('2 filas no se pudieron cargar:'), findsOneWidget);
      expect(find.textContaining('Fila 3: Usa mínimo 3 caracteres'), findsOneWidget);
      expect(find.textContaining('Fila 4: La categoría "Charcutería"'),
          findsOneWidget);
    });

    testWidgets('al volver al catálogo la lista ya trae los productos cargados',
        (tester) async {
      final env = await _pumpCatalogo(tester);
      env.selectorCsv.archivo = const ArchivoCsv(
        nombre: 'productos.csv',
        contenido: 'nombre,categoria\nLeche entera,Lácteos\n',
      );
      await abrirCsv(tester);
      await tester.tap(find.text('Elegir archivo CSV'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Mi catálogo'), findsOneWidget);
      expect(find.text('Leche entera'), findsOneWidget);
    });

    testWidgets('un archivo con formato inválido muestra el error', (tester) async {
      final env = await _pumpCatalogo(tester);
      env.selectorCsv.archivo =
          const ArchivoCsv(nombre: 'malo.csv', contenido: 'marca\nDiana\n');
      await abrirCsv(tester);

      await tester.tap(find.text('Elegir archivo CSV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('"nombre" y "categoria"'), findsWidgets);
      expect(find.textContaining('Se cargó'), findsNothing);
    });

    testWidgets('cancelar el selector no muestra ningún resultado', (tester) async {
      await _pumpCatalogo(tester);
      await abrirCsv(tester);

      await tester.tap(find.text('Elegir archivo CSV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Se cargó'), findsNothing);
      expect(find.textContaining('no se pudieron'), findsNothing);
    });
  });
}
