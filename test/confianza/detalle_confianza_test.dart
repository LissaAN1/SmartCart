import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/busqueda/presentation/pages/detalle_producto_page.dart';
import 'package:smartcart/features/cart/presentation/bloc/carrito_bloc.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/favoritos/presentation/bloc/favoritos_bloc.dart';

import '../busqueda/busqueda_datos.dart';
import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/pump_helpers.dart';

/// Los precios del arroz (busqueda_datos.dart): del comercio con promoción de
/// hoy a las 9:30, ayer a las 18:00 y el 10 de noviembre (agotado).
final _hoy = DateTime(2026, 11, 15, 12);

/// Abre el detalle del arroz con la fecha de "hoy" fija. Con [conCliente]
/// la pantalla recibe el carrito y los favoritos, como desde el Home.
Future<(TestEnv, ClienteBlocs?)> _pumpDetalle(
  WidgetTester tester, {
  DateTime? hoy,
  bool conCliente = false,
  double ancho = 420,
  void Function(TestEnv env)? prepare,
}) async {
  // Alta: cada establecimiento ocupa más y la lista solo arma lo que se ve.
  setScreenSize(tester, ancho, 2600);
  final env = entornoBusqueda();
  if (conCliente) env.iniciarSesionComoCliente();
  prepare?.call(env);
  final cliente = conCliente ? env.clienteBlocs() : null;

  Widget pagina = BlocProvider(
    create: (_) => env.detalleBloc(ConsultaPorClave(arrozDetalle.clave))
      ..add(DetalleProductoStarted()),
    child: DetalleProductoPage(reloj: () => hoy ?? _hoy),
  );
  if (cliente != null) {
    pagina = MultiBlocProvider(
      providers: [
        BlocProvider<CarritoBloc>.value(value: cliente.carrito),
        BlocProvider<FavoritosBloc>.value(value: cliente.favoritos),
      ],
      child: pagina,
    );
  }
  await tester.pumpWidget(MaterialApp(home: pagina));
  await tester.pumpAndSettle();
  return (env, cliente);
}

Future<void> _reportarPrimero(WidgetTester tester, {String? motivo}) async {
  await tester.tap(find.text('Reportar precio incorrecto').first);
  await tester.pumpAndSettle();
  if (motivo != null) await tester.enterText(find.byType(TextField), motivo);
  await tester.tap(find.text('Enviar reporte'));
  await tester.pumpAndSettle();
}

void main() {
  group('Escenario 1: precio reciente de un comercio', () {
    testWidgets('cada precio muestra su fuente, su fecha y su confianza',
        (tester) async {
      await _pumpDetalle(tester);

      expect(find.text('Fuente: Comercio'), findsNWidgets(3));
      expect(find.text('Actualizado 15 nov 2026 · 09:30 (hoy)'), findsOneWidget);
      expect(find.text('Actualizado 14 nov 2026 · 18:00 (ayer)'), findsOneWidget);
      expect(find.text('Actualizado 10 nov 2026 · 08:00 (hace 5 días)'),
          findsOneWidget);
    });

    testWidgets('los de hoy y ayer tienen confianza alta; el de 5 días, media',
        (tester) async {
      await _pumpDetalle(tester);

      expect(find.text('Confianza alta'), findsNWidgets(2));
      expect(find.text('Confianza media'), findsOneWidget);
      expect(find.text('Desactualizado'), findsNothing);
    });

    testWidgets('explica cómo se mide la confianza y el límite de días',
        (tester) async {
      await _pumpDetalle(tester);

      expect(find.textContaining('más de 7 días'), findsOneWidget);
      expect(find.textContaining('desactualizado'), findsOneWidget);
    });
  });

  group('Escenario 2: precio desactualizado', () {
    testWidgets('pasados 7 días se marcan desactualizados y bajan a confianza baja',
        (tester) async {
      await _pumpDetalle(tester, hoy: DateTime(2026, 11, 25, 12));

      expect(find.text('Desactualizado'), findsNWidgets(3));
      expect(find.text('Confianza baja'), findsNWidgets(3));
      expect(find.text('Confianza alta'), findsNothing);
    });

    testWidgets('solo el viejo se marca cuando hoy es el 18 de noviembre',
        (tester) async {
      // El del 10 tiene 8 días; los del 14 y el 15, 4 y 3.
      await _pumpDetalle(tester, hoy: DateTime(2026, 11, 18, 12));

      expect(find.text('Desactualizado'), findsOneWidget);
      expect(find.text('Confianza baja'), findsOneWidget);
    });
  });

  group('Escenario 3: reportar un precio incorrecto', () {
    testWidgets('cada precio tiene su botón', (tester) async {
      await _pumpDetalle(tester);

      expect(find.text('Reportar precio incorrecto'), findsNWidgets(3));
    });

    testWidgets('al tocarlo pide el motivo (opcional) antes de enviar',
        (tester) async {
      final (env, _) = await _pumpDetalle(tester);

      await tester.tap(find.text('Reportar precio incorrecto').first);
      await tester.pumpAndSettle();

      expect(find.text('Motivo (opcional)'), findsOneWidget);
      expect(find.text('Enviar reporte'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.textContaining('Minimercado La Esquina · \$ 4.200'),
          findsOneWidget);
      expect(env.reporteIncorrecto.reportes, isEmpty);
    });

    testWidgets('al enviar, registra el reporte y avisa', (tester) async {
      final (env, _) = await _pumpDetalle(tester);

      await _reportarPrimero(tester, motivo: 'En la tienda vale 4.000');

      expect(env.reporteIncorrecto.reportes.single.idProducto, 'p1');
      expect(env.reporteIncorrecto.reportes.single.motivo,
          'En la tienda vale 4.000');
      expect(find.text('Gracias, enviamos tu reporte para revisarlo.'),
          findsOneWidget);
    });

    testWidgets('el precio reportado pasa a "Reporte enviado" y no se repite',
        (tester) async {
      final (env, _) = await _pumpDetalle(tester);

      await _reportarPrimero(tester);

      expect(find.text('Reporte enviado'), findsOneWidget);
      expect(find.text('Reportar precio incorrecto'), findsNWidgets(2));
      expect(env.reporteIncorrecto.reportes, hasLength(1));
    });

    testWidgets('sin escribir motivo también se puede enviar', (tester) async {
      final (env, _) = await _pumpDetalle(tester);

      await _reportarPrimero(tester);

      expect(env.reporteIncorrecto.reportes.single.motivo, isNull);
    });

    testWidgets('cancelar no envía nada', (tester) async {
      final (env, _) = await _pumpDetalle(tester);

      await tester.tap(find.text('Reportar precio incorrecto').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'No lo voy a enviar');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(env.reporteIncorrecto.reportes, isEmpty);
      expect(find.text('Enviar reporte'), findsNothing);
      expect(find.text('Reportar precio incorrecto'), findsNWidgets(3));
    });

    testWidgets('un precio con reporte pendiente avisa que ya se reportó',
        (tester) async {
      final (env, _) = await _pumpDetalle(tester, prepare: (env) {
        env.reporteIncorrecto.reportes.add((idProducto: 'p1', motivo: null));
      });

      await _reportarPrimero(tester);

      expect(find.text('Ya reportaste este precio; lo estamos revisando.'),
          findsOneWidget);
      expect(env.reporteIncorrecto.reportes, hasLength(1));
    });

    testWidgets('si falla, avisa y el botón sigue disponible', (tester) async {
      await _pumpDetalle(tester, prepare: (env) {
        env.reporteIncorrecto.error = const AuthFailure('Ese precio ya no está publicado.');
      });

      await _reportarPrimero(tester);

      expect(find.text('Ese precio ya no está publicado.'), findsOneWidget);
      expect(find.text('Reporte enviado'), findsNothing);
      expect(find.text('Reportar precio incorrecto'), findsNWidgets(3));
    });

    testWidgets('cada tienda se reporta por separado', (tester) async {
      final (env, _) = await _pumpDetalle(tester);

      await _reportarPrimero(tester);
      await tester.pump(const Duration(seconds: 5));
      await _reportarPrimero(tester);

      expect(env.reporteIncorrecto.reportes.map((r) => r.idProducto),
          ['p1', 'p2']);
      expect(find.text('Reporte enviado'), findsNWidgets(2));
    });
  });

  group('Botones de agregar y favoritos (HU-17 desde el detalle)', () {
    testWidgets('sin el carrito del cliente no se muestran', (tester) async {
      await _pumpDetalle(tester);

      expect(find.byTooltip('Agregar al carrito'), findsNothing);
      expect(find.byTooltip('Guardar en favoritos'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con el carrito del cliente: favorito en los 3 y agregar solo '
        'en los disponibles', (tester) async {
      await _pumpDetalle(tester, conCliente: true);

      expect(find.byTooltip('Guardar en favoritos'), findsNWidgets(3));
      expect(find.byTooltip('Agregar al carrito'), findsNWidgets(2));
    });

    testWidgets('agregar al carrito desde el detalle lo guarda y avisa',
        (tester) async {
      final (env, cliente) = await _pumpDetalle(tester, conCliente: true);

      await tester.tap(find.byTooltip('Agregar al carrito').first);
      await tester.pumpAndSettle();

      expect(env.cliente.carrito.lineas.single.idProducto, 'p1');
      expect(cliente!.carrito.state.items, hasLength(1));
      expect(find.textContaining('se agregó al carrito'), findsOneWidget);
    });

    testWidgets('marcar favorito desde el detalle lo guarda y avisa',
        (tester) async {
      final (_, cliente) = await _pumpDetalle(tester, conCliente: true);

      await tester.tap(find.byTooltip('Guardar en favoritos').first);
      await tester.pumpAndSettle();

      expect(cliente!.favoritos.state.ids.productos, contains('p1'));
      expect(find.text('Guardado en tus favoritos'), findsOneWidget);
    });
  });

  group('Argumentos de ruta con los blocs del cliente', () {
    test('sin ConBlocsDelCliente se devuelve el argumento tal cual', () {
      const consulta = ConsultaPorClave('cb:1');

      final (propio, blocs) = desempacarArgumentos(consulta);

      expect(propio, same(consulta));
      expect(blocs, isNull);
    });

    test('con ConBlocsDelCliente se separan el argumento y los blocs', () async {
      final env = entornoBusqueda()..iniciarSesionComoCliente();
      final blocs = env.clienteBlocs();
      const consulta = ConsultaPorCodigo('7701234567890');

      final (propio, recibidos) =
          desempacarArgumentos(ConBlocsDelCliente(consulta, blocs));

      expect(propio, same(consulta));
      expect(recibidos, same(blocs));
      await blocs.cerrar();
    });

    testWidgets('clienteBlocsOrNull es null si el árbol no los tiene',
        (tester) async {
      late BuildContext contexto;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          contexto = c;
          return const SizedBox();
        }),
      ));

      expect(clienteBlocsOrNull(contexto), isNull);
    });
  });

  group('En pantallas angostas', () {
    testWidgets('en 320 px no hay desbordes con todo a la vez', (tester) async {
      await _pumpDetalle(tester,
          ancho: 320, conCliente: true, hoy: DateTime(2026, 11, 25));

      expect(tester.takeException(), isNull);
      expect(find.text('Desactualizado'), findsNWidgets(3));
    });

    testWidgets('la hoja del motivo en 320 px tampoco desborda',
        (tester) async {
      await _pumpDetalle(tester, ancho: 320);

      await tester.tap(find.text('Reportar precio incorrecto').first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
