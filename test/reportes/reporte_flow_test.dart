import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/reportes/domain/repository/selector_foto.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/presentation/bloc/reporte_form_bloc.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_args.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_establecimiento_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_form_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/reporte_producto_page.dart';
import 'package:smartcart/features/reportes/presentation/pages/sugerir_establecimiento_page.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/ubicacion_bloc.dart';

import '../support/fakes.dart';
import '../support/pump_helpers.dart';

/// Lo que devuelve el escáner de mentira: la cámara no existe en las pruebas.
String _codigoEscaneado = '7701234567890';

/// Si la página de productos abre el escáner al entrar. La mayoría de las
/// pruebas lo apagan para empezar por la lista; el grupo "escaneo directo" lo
/// enciende.
bool _escanearAlEntrar = false;

/// Monta el flujo del reporte con las mismas rutas que arma `AppRouter` y abre
/// el primer paso desde una pantalla de inicio.
Future<TestEnv> _pump(
  WidgetTester tester, {
  void Function(TestEnv env)? prepare,
  bool escanearAlEntrar = false,
}) async {
  setScreenSize(tester, 420, 900);
  _codigoEscaneado = '7701234567890';
  _escanearAlEntrar = escanearAlEntrar;
  final env = TestEnv()..iniciarSesionComoColaborador();
  prepare?.call(env);

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        Widget? page;
        switch (settings.name) {
          case AppRoutes.reporteEstablecimiento:
            page = BlocProvider(
              create: (_) => env.ubicacionBloc()..add(UbicacionSolicitada()),
              child: ReporteEstablecimientoPage(
                crearLista: env.establecimientosBloc,
              ),
            );
          case AppRoutes.reporteProducto when args is EstablecimientoCercano:
            page = ReporteProductoPage(
              establecimiento: args,
              crearLista: env.busquedaProductosBloc,
              escanearAlEntrar: _escanearAlEntrar,
            );
          case AppRoutes.reporteFormulario when args is ReporteFormArgs:
            page = BlocProvider(
              create: (_) => env.reporteFormBloc(),
              child: ReporteFormPage(args: args),
            );
          case AppRoutes.reporteSugerir:
            page = BlocProvider(
              create: (_) => env.sugerenciaBloc(),
              child: const SugerirEstablecimientoPage(),
            );
          case AppRoutes.reporteEscaner:
            return MaterialPageRoute<String>(
              settings: settings,
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _codigoEscaneado),
                    child: const Text('Código leído'),
                  ),
                ),
              ),
            );
        }
        if (page == null) return null;
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => page!,
        );
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed<bool>(AppRoutes.reporteEstablecimiento),
              child: const Text('Inicio'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Inicio'));
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

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Cierra el escáner de mentira sin leer nada, como quien lo cancela.
Future<void> _cancelarEscaner(WidgetTester tester) async {
  Navigator.of(tester.element(find.text('Código leído'))).pop();
  await tester.pumpAndSettle();
}

Future<void> _tocarEnviar(WidgetTester tester) =>
    _tocar(tester, find.widgetWithText(FilledButton, 'Enviar reporte'));

Future<void> _tocarFoto(WidgetTester tester) =>
    _tocar(tester, find.text('Tomar foto de la etiqueta'));

/// Llega al formulario del reporte eligiendo el primer establecimiento y
/// producto de la lista.
Future<void> _irAlFormulario(WidgetTester tester) async {
  await tester.tap(find.text('Minimercado La Esquina'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Arroz blanco 500 g'));
  await tester.pumpAndSettle();
}

void main() {
  group('Paso 1 · establecimiento', () {
    testWidgets('lista los establecimientos cercanos con su distancia',
        (tester) async {
      await _pump(tester, prepare: (env) {
        env.reportes.establecimientos
            .add(establecimientoDePrueba(id: 'c2', nombre: 'Tienda Doña Rosa'));
      });

      expect(find.text('¿En qué establecimiento estás?'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(find.text('Calle 10 # 5-20 · Cali'), findsNWidgets(2));
      expect(find.text('33 m'), findsNWidgets(2));
    });

    testWidgets('si el GPS falla muestra el motivo y deja reintentar',
        (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) => env.servicioUbicacion.error =
            const AuthFailure('La ubicación del dispositivo está apagada.'),
      );
      expect(find.text('La ubicación del dispositivo está apagada.'),
          findsOneWidget);

      env.servicioUbicacion.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Minimercado La Esquina'), findsOneWidget);
    });

    testWidgets('sin establecimientos cerca lo dice y deja sugerir uno',
        (tester) async {
      await _pump(tester, prepare: (env) => env.reportes.establecimientos.clear());

      expect(find.textContaining('No hay establecimientos con ubicación'),
          findsOneWidget);
      expect(find.text('Sugerir establecimiento'), findsOneWidget);
    });

    testWidgets('quien no tiene el modo Colaborador ve el aviso', (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.iniciarSesionCon({}),
      );

      expect(find.textContaining('modo Colaborador'), findsOneWidget);
    });
  });

  group('Paso 2 · producto', () {
    Future<void> abrirProductos(WidgetTester tester) async {
      await tester.tap(find.text('Minimercado La Esquina'));
      await tester.pumpAndSettle();
    }

    TestEnv? envActual;

    Future<void> pumpConDosProductos(WidgetTester tester) async {
      envActual = await _pump(tester, prepare: (env) {
        env.reportes.productosPorComercio['c1'] = [
          productoDePrueba,
          const Producto(
            id: 'p2',
            nombre: 'Leche entera 1 L',
            marca: 'Alpina',
            codigoBarras: '7709990001112',
            idCategoria: 'cat-lacteos',
            categoria: 'Lácteos',
          ),
        ];
      });
      await abrirProductos(tester);
    }

    testWidgets('lista los productos del establecimiento elegido',
        (tester) async {
      await pumpConDosProductos(tester);

      expect(find.text('Elige el producto'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
    });

    testWidgets('se busca por nombre o marca', (tester) async {
      await pumpConDosProductos(tester);

      await tester.enterText(find.byType(TextField), 'alpina');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsNothing);
    });

    testWidgets('sin coincidencias lo dice', (tester) async {
      await pumpConDosProductos(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('No encontramos productos con "zzz".'), findsOneWidget);
    });

    testWidgets('escanear un código busca ese producto y abre su formulario',
        (tester) async {
      await pumpConDosProductos(tester);
      _codigoEscaneado = '7709990001112';

      await tester.tap(find.byTooltip('Escanear código de barras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();

      // Con un único producto, pasa directo al formulario del reporte.
      expect(find.text('Precio (COP)'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsNothing);
      expect(envActual!.reportes.consultas.last.esCodigo, isTrue);
      expect(envActual!.reportes.consultas.last.texto, '7709990001112');
    });

    testWidgets('un código que no está en el establecimiento se avisa',
        (tester) async {
      await pumpConDosProductos(tester);
      _codigoEscaneado = '1234567890123';

      await tester.tap(find.byTooltip('Escanear código de barras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos un producto con ese código'),
          findsOneWidget);
    });

    testWidgets('quitar la búsqueda vuelve a listar todo', (tester) async {
      await pumpConDosProductos(tester);
      await tester.enterText(find.byType(TextField), 'alpina');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Quitar búsqueda'));
      await tester.pumpAndSettle();

      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Leche entera 1 L'), findsOneWidget);
    });
  });

  group('Paso 2 · escaneo directo al elegir el establecimiento', () {
    /// Elige el establecimiento: con el escáner activo, la cámara se abre sola.
    Future<TestEnv> entrar(
      WidgetTester tester, {
      void Function(TestEnv env)? prepare,
    }) async {
      final env = await _pump(tester, prepare: prepare, escanearAlEntrar: true);
      await tester.tap(find.text('Minimercado La Esquina'));
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('la cámara se abre sola, sin tocar el ícono del escáner',
        (tester) async {
      await entrar(tester);

      // Es la pantalla del escáner (de mentira), no la lista de productos.
      expect(find.text('Código leído'), findsOneWidget);
      expect(find.text('Elige el producto'), findsNothing);
    });

    testWidgets('si el código es de un producto, pasa directo al formulario',
        (tester) async {
      await entrar(tester);

      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();

      expect(find.text('Precio (COP)'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Elige el producto'), findsNothing);
    });

    testWidgets('el reporte completo se hace sin tocar la lista de productos',
        (tester) async {
      final env = await entrar(tester);
      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();

      await _escribir(tester, 'Precio (COP)', '4900');
      await _tocarFoto(tester);
      await _tocarEnviar(tester);

      expect(find.text('Reporte enviado'), findsOneWidget);
      expect(env.reportes.reportes.single.datos.producto.id, 'p1');
    });

    testWidgets('si el código no está en el establecimiento, avisa y deja buscar',
        (tester) async {
      await entrar(tester);
      _codigoEscaneado = '1234567890123';

      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos un producto con ese código'),
          findsOneWidget);
      expect(find.text('Precio (COP)'), findsNothing);
      // Sigue pudiendo buscar por nombre.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('si cancela el escáner se queda en la lista para buscar por nombre',
        (tester) async {
      await entrar(tester);

      await _cancelarEscaner(tester);

      expect(find.text('Elige el producto'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Precio (COP)'), findsNothing);
    });

    testWidgets('volver atrás desde el formulario no lo abre otra vez',
        (tester) async {
      await entrar(tester);
      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();
      expect(find.text('Precio (COP)'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Elige el producto'), findsOneWidget);
      expect(find.text('Precio (COP)'), findsNothing);
      expect(find.text('Código escaneado: 7701234567890'), findsOneWidget);
    });

    testWidgets('sin cámara (escritorio) no abre el escáner solo', (tester) async {
      // Flutter exige restablecer la variable antes de que termine la prueba.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await entrar(tester);

        expect(find.text('Código leído'), findsNothing);
        expect(find.text('Elige el producto'), findsOneWidget);
        expect(find.byTooltip('Escanear código de barras'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('el ícono sigue sirviendo para escanear otro producto',
        (tester) async {
      await entrar(tester);
      await _cancelarEscaner(tester);

      await tester.tap(find.byTooltip('Escanear código de barras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Código leído'));
      await tester.pumpAndSettle();

      expect(find.text('Precio (COP)'), findsOneWidget);
    });
  });

  group('Paso 3 · formulario del reporte', () {
    testWidgets('sin llenar el precio muestra el error y no envía',
        (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);

      await _tocarEnviar(tester);

      expect(find.text('Escribe el precio'), findsOneWidget);
      expect(env.reportes.reportes, isEmpty);
    });

    testWidgets('una promoción mayor que el precio se avisa en el campo',
        (tester) async {
      await _pump(tester);
      await _irAlFormulario(tester);

      await _escribir(tester, 'Precio (COP)', '4900');
      await _escribir(tester, 'Precio en promoción (opcional)', '5000');
      await _tocarEnviar(tester);

      expect(find.text('La promoción debe ser menor que el precio normal'),
          findsOneWidget);
    });

    testWidgets('escenario 3: sin foto muestra que es obligatoria',
        (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);

      await _escribir(tester, 'Precio (COP)', '4900');
      await _tocarEnviar(tester);

      expect(find.text('La foto de la etiqueta es obligatoria.'), findsOneWidget);
      expect(env.reportes.reportes, isEmpty);
      expect(env.servicioUbicacion.llamadas, 1,
          reason: 'solo la del primer paso; el envío sin foto no pide el GPS');
    });

    testWidgets('escenario 1: reporte exitoso queda enviado y vuelve al inicio',
        (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);

      await _escribir(tester, 'Precio (COP)', '4.900');
      await _escribir(tester, 'Precio en promoción (opcional)', '4500');
      await tester.ensureVisible(find.text('El producto está agotado'));
      await tester.tap(find.text('El producto está agotado'));
      await tester.pumpAndSettle();
      await _tocarFoto(tester);
      expect(find.text('Cambiar foto'), findsOneWidget);

      await _tocarEnviar(tester);

      expect(find.text('Reporte enviado'), findsOneWidget);
      final guardado = env.reportes.reportes.single;
      expect(guardado.datos.precio, 4900);
      expect(guardado.datos.precioPromocional, 4500);
      expect(guardado.datos.agotado, isTrue);
      expect(guardado.datos.producto.id, 'p1');

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      // Volvió a la pantalla de inicio: todo el flujo se cerró.
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Reportar precio'), findsNothing);
    });

    testWidgets('escenario 2: lejos del establecimiento se rechaza y se explica',
        (tester) async {
      final env = await _pump(tester, prepare: (env) {
        env.reportes.establecimientos
          ..clear()
          ..add(establecimientoDePrueba(ubicacion: ubicacionLejana));
      });
      await _irAlFormulario(tester);

      await _escribir(tester, 'Precio (COP)', '4900');
      await _tocarFoto(tester);
      await _tocarEnviar(tester);

      expect(
        find.textContaining('Debes estar en el establecimiento para reportar'),
        findsOneWidget,
      );
      expect(find.text('Reporte enviado'), findsNothing);
      expect(env.reportes.reportes, isEmpty);
    });

    testWidgets('si la cámara no tiene permiso muestra el motivo',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.selectorFoto.error = const AuthFailure(
            'Necesitamos el permiso de la cámara para fotografiar la etiqueta.'),
      );
      await _irAlFormulario(tester);

      await _tocarFoto(tester);

      expect(find.textContaining('permiso de la cámara'), findsOneWidget);
      expect(find.text('Tomar foto de la etiqueta'), findsOneWidget);
    });

    testWidgets('cancelar la cámara no cambia nada', (tester) async {
      await _pump(tester, prepare: (env) => env.selectorFoto.foto = null);
      await _irAlFormulario(tester);

      await _tocarFoto(tester);

      expect(find.text('Tomar foto de la etiqueta'), findsOneWidget);
      expect(find.text('Cambiar foto'), findsNothing);
    });

    testWidgets('se puede quitar la foto tomada', (tester) async {
      await _pump(tester);
      await _irAlFormulario(tester);
      await _tocarFoto(tester);

      await _tocar(tester, find.text('Quitar'));

      expect(find.text('Tomar foto de la etiqueta'), findsOneWidget);
    });

    testWidgets('si la base rechaza el envío se queda en el formulario',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.reportes.enviarError =
            const AuthFailure('Ese establecimiento no está disponible.'),
      );
      await _irAlFormulario(tester);
      await _escribir(tester, 'Precio (COP)', '4900');
      await _tocarFoto(tester);

      await _tocarEnviar(tester);

      expect(find.text('Ese establecimiento no está disponible.'), findsOneWidget);
      expect(find.text('Enviar reporte'), findsOneWidget);
    });
  });

  group('Sugerir un establecimiento', () {
    testWidgets('sin completar lo obligatorio muestra los errores',
        (tester) async {
      final env = await _pump(tester);
      await _tocar(tester, find.text('Sugerir establecimiento'));

      await _tocar(tester, find.widgetWithText(FilledButton, 'Enviar sugerencia'));

      expect(find.text('Escribe el nombre del establecimiento'), findsOneWidget);
      expect(find.text('Escribe la dirección'), findsOneWidget);
      expect(find.text('Escribe la ciudad o el barrio'), findsOneWidget);
      expect(env.reportes.sugerencias, isEmpty);
    });

    testWidgets('completarla guarda la sugerencia con la ubicación del colaborador',
        (tester) async {
      final env = await _pump(tester);
      await _tocar(tester, find.text('Sugerir establecimiento'));

      await _escribir(tester, 'Nombre del establecimiento', 'Tienda Doña Rosa');
      await _escribir(tester, 'Dirección', 'Carrera 5 # 10-20');
      await _escribir(tester, 'Ciudad o barrio', 'Cali, San Fernando');
      await _tocar(tester, find.widgetWithText(FilledButton, 'Enviar sugerencia'));

      expect(find.text('Sugerencia enviada'), findsOneWidget);
      final s = env.reportes.sugerencias.single;
      expect(s.datos.nombre, 'Tienda Doña Rosa');
      expect(s.ubicacion, ubicacionColaborador);

      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      // Vuelve a la lista de establecimientos.
      expect(find.text('¿En qué establecimiento estás?'), findsOneWidget);
    });

    testWidgets('si falla el envío muestra el motivo', (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.reportes.sugerirError =
            const AuthFailure('No tienes permiso para realizar esta acción.'),
      );
      await _tocar(tester, find.text('Sugerir establecimiento'));
      await _escribir(tester, 'Nombre del establecimiento', 'Tienda Doña Rosa');
      await _escribir(tester, 'Dirección', 'Carrera 5 # 10-20');
      await _escribir(tester, 'Ciudad o barrio', 'Cali');

      await _tocar(tester, find.widgetWithText(FilledButton, 'Enviar sugerencia'));

      expect(find.text('No tienes permiso para realizar esta acción.'),
          findsOneWidget);
    });
  });

  group('formatoDistancia', () {
    test('en metros hasta el kilómetro y en km después', () {
      expect(formatoDistancia(33.4), '33 m');
      expect(formatoDistancia(999.4), '999 m');
      expect(formatoDistancia(1000), '1,0 km');
      expect(formatoDistancia(1240), '1,2 km');
    });
  });

  group('ReporteFormBloc en pantalla', () {
    testWidgets('el estado enviado cierra el flujo una sola vez', (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);
      await _escribir(tester, 'Precio (COP)', '4900');
      await _tocarFoto(tester);
      await _tocarEnviar(tester);
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();

      expect(env.reportes.reportes.length, 1);
      expect(find.byType(ReporteFormPage), findsNothing);
      expect(ReporteFormStatus.values, contains(ReporteFormStatus.enviado));
    });
  });

  group('Primero el producto, después la foto', () {
    testWidgets('al elegir el establecimiento lo primero es la lista de '
        'productos: la cámara no se abre sola', (tester) async {
      setScreenSize(tester, 420, 900);
      final env = TestEnv()..iniciarSesionComoColaborador();
      var abrioEscaner = false;
      // La página con su configuración por defecto, como la arma AppRouter.
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.reporteEscaner) abrioEscaner = true;
          return null;
        },
        home: ReporteProductoPage(
          establecimiento: establecimientoDePrueba(),
          crearLista: env.busquedaProductosBloc,
        ),
      ));
      await tester.pumpAndSettle();

      expect(abrioEscaner, isFalse);
      expect(find.text('Elige el producto'), findsOneWidget);
      expect(find.text('Arroz blanco 500 g'), findsOneWidget);
      // El escáner sigue disponible como opción del buscador.
      expect(find.byTooltip('Escanear código de barras'), findsOneWidget);
    });

    testWidgets('con cámara ofrece tomar la foto o subir una', (tester) async {
      await _pump(tester);
      await _irAlFormulario(tester);

      expect(find.text('Tomar foto de la etiqueta'), findsOneWidget);
      expect(find.text('Subir foto'), findsOneWidget);
    });

    testWidgets('"Tomar foto" pide la foto a la cámara', (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);

      await _tocar(tester, find.text('Tomar foto de la etiqueta'));

      expect(env.selectorFoto.origenes, [OrigenFoto.camara]);
      expect(find.text('Cambiar foto'), findsOneWidget);
    });

    testWidgets('"Subir foto" pide la foto a la galería', (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);

      await _tocar(tester, find.text('Subir foto'));

      expect(env.selectorFoto.origenes, [OrigenFoto.galeria]);
      expect(find.text('Cambiar foto'), findsOneWidget);
      expect(find.text('Tomar foto de la etiqueta'), findsNothing);
    });

    testWidgets('una foto subida se envía con el reporte', (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);
      await _escribir(tester, 'Precio (COP)', '4.900');
      await _tocar(tester, find.text('Subir foto'));

      await _tocarEnviar(tester);

      expect(find.text('Reporte enviado'), findsOneWidget);
      expect(env.reportes.reportes.single.foto.bytes, isNotEmpty);
    });

    testWidgets('"Cambiar foto" deja elegir entre la cámara y la galería',
        (tester) async {
      final env = await _pump(tester);
      await _irAlFormulario(tester);
      await _tocar(tester, find.text('Subir foto'));

      await _tocar(tester, find.text('Cambiar foto'));
      expect(find.text('Tomar foto'), findsOneWidget);
      expect(find.text('Subir foto de la galería'), findsOneWidget);

      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();

      expect(env.selectorFoto.origenes,
          [OrigenFoto.galeria, OrigenFoto.camara]);
    });

    testWidgets('sin cámara (web o escritorio) solo se ofrece subir la imagen',
        (tester) async {
      final env = await _pump(
        tester,
        prepare: (env) => env.selectorFoto.hayCamara = false,
      );
      await _irAlFormulario(tester);

      expect(find.text('Tomar foto de la etiqueta'), findsNothing);
      expect(find.text('Subir foto de la etiqueta'), findsOneWidget);

      await _tocar(tester, find.text('Subir foto de la etiqueta'));
      expect(env.selectorFoto.origenes, [OrigenFoto.galeria]);

      // "Cambiar foto" no pregunta: solo hay galería.
      await _tocar(tester, find.text('Cambiar foto'));
      expect(find.text('Subir foto de la galería'), findsNothing);
      expect(env.selectorFoto.origenes,
          [OrigenFoto.galeria, OrigenFoto.galeria]);
    });

    test('el caso de uso toma la foto con la cámara si no se le dice otra '
        'cosa', () async {
      final env = TestEnv();

      await env.tomarFoto();
      await env.tomarFoto(OrigenFoto.galeria);

      expect(env.selectorFoto.origenes,
          [OrigenFoto.camara, OrigenFoto.galeria]);
      expect(env.tomarFoto.hayCamara, isTrue);
    });

    test('el Bloc pide la foto al origen que se le indica', () async {
      final env = TestEnv()..iniciarSesionComoColaborador();
      final bloc = env.reporteFormBloc();
      addTearDown(bloc.close);

      bloc.add(ReporteFotoSolicitada(origen: OrigenFoto.galeria));
      await bloc.stream.firstWhere((s) => s.foto != null);

      expect(env.selectorFoto.origenes, [OrigenFoto.galeria]);
      expect(bloc.hayCamara, isTrue);
    });
  });
}
