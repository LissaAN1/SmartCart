import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/presentation/widgets/aviso_notificaciones.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/presentation/pages/mis_ordenes_page.dart';
import 'package:smartcart/features/seguimiento/domain/notificaciones_push.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/detalle_orden_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/ordenes_cliente_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/push_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/pages/detalle_orden_page.dart';
import 'package:smartcart/features/seguimiento/presentation/widgets/avisos_push.dart';

import '../support/fakes.dart';
import '../support/fakes_seguimiento.dart';
import '../support/pump_helpers.dart';

List<Orden> _ordenes() => [
      ordenSeguimiento(),
      ordenSeguimiento(
        id: 'o102',
        numero: 102,
        estado: EstadoOrden.enPreparacion,
        tipo: TipoEntrega.entrega,
        creadoEn: DateTime(2026, 11, 27, 16, 20),
      ),
      ordenSeguimiento(
        id: 'o90',
        numero: 90,
        estado: EstadoOrden.recogida,
        cerradaEn: DateTime(2026, 11, 20),
        creadoEn: DateTime(2026, 11, 19, 8, 0),
      ),
    ];

/// Monta "Mis órdenes" con las rutas que arma `AppRouter` para el detalle.
Future<TestEnv> _pumpOrdenes(
  WidgetTester tester, {
  List<Orden>? ordenes,
  double ancho = 420,
}) async {
  setScreenSize(tester, ancho, 1400);
  final env = TestEnv()..iniciarSesionComoClienteConOrdenes(ordenes ?? _ordenes());
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        if (settings.name == AppRoutes.detalleOrden && args is String) {
          return MaterialPageRoute<bool>(
            settings: settings,
            builder: (_) => BlocProvider(
              create: (_) =>
                  env.detalleOrdenBloc(args)..add(DetalleOrdenStarted()),
              child: DetalleOrdenPage(ahora: () => ahoraSeguimiento),
            ),
          );
        }
        return stubRoutes(settings);
      },
      home: MultiBlocProvider(
        providers: [
          BlocProvider<PaginatedBloc<Orden>>(
            create: (_) => env.ordenesClienteBloc()..add(PaginatedStarted()),
          ),
          BlocProvider(
            create: (_) => env.conteoOrdenesBloc()..add(ConteoOrdenesPedido()),
          ),
        ],
        child: MisOrdenesPage(ahora: () => ahoraSeguimiento),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return env;
}

Future<void> _ver(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Mis órdenes', () {
    testWidgets('muestra las pestañas, el aviso y las órdenes en curso',
        (tester) async {
      await _pumpOrdenes(tester);

      expect(find.text('Mis órdenes'), findsOneWidget);
      expect(find.text('Gestiona tus compras y recogidas'), findsOneWidget);
      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      // Dos órdenes en curso.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('¡Tu orden #105 está lista!'), findsOneWidget);
      expect(find.text('ÓRDENES ACTIVAS'), findsOneWidget);
      expect(find.text('ORDEN #105'), findsOneWidget);
      expect(find.text('Hoy, 9:15 AM'), findsOneWidget);
      expect(find.text('LISTO PARA RECOGER'), findsOneWidget);
      expect(find.text('ORDEN #102'), findsOneWidget);
      expect(find.text('Ayer, 4:20 PM'), findsOneWidget);
      expect(find.text('EN PROCESO'), findsOneWidget);
      expect(find.text('Ver código de recogida'), findsOneWidget);
      // La entrega muestra el paso del repartidor.
      expect(find.text('EN CAMINO'), findsOneWidget);
      // La del historial no aparece en "En curso".
      expect(find.text('ORDEN #90'), findsNothing);
    });

    testWidgets('el historial muestra las cerradas y deja calificar',
        (tester) async {
      await _pumpOrdenes(tester);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('HISTORIAL'), findsOneWidget);
      expect(find.text('ORDEN #90'), findsOneWidget);
      expect(find.text('RECOGIDA'), findsOneWidget);
      expect(find.text('Calificar al comercio'), findsOneWidget);
      expect(find.text('ORDEN #105'), findsNothing);
      // En el historial no hay barra de progreso ni aviso.
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('está lista'), findsNothing);
    });

    testWidgets('escenario 3: sin compras dice "Aún no tienes órdenes"',
        (tester) async {
      await _pumpOrdenes(tester, ordenes: const []);

      expect(find.text('Aún no tienes órdenes'), findsOneWidget);
    });

    testWidgets('el aviso abre el detalle de la orden lista', (tester) async {
      await _pumpOrdenes(tester);

      await tester.tap(find.text('¡Tu orden #105 está lista!'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de Orden'), findsOneWidget);
      expect(find.text('SC-105'), findsOneWidget);
    });

    testWidgets(
        'escenario 2: confirmar la recogida cierra la orden y al volver '
        'pasa al historial', (tester) async {
      final env = await _pumpOrdenes(tester);
      await tester.tap(find.text('Ver código de recogida'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('boton-confirmar')));
      await tester.pumpAndSettle();
      expect(find.text('¡Listo! Cerramos tu orden. Gracias por tu compra.'),
          findsOneWidget);
      expect(find.textContaining('Confirmaste la recogida'), findsOneWidget);
      expect(env.seg.seguimiento.confirmadas, ['o105']);

      await tester.tap(find.byType(BotonAtras));
      await tester.pumpAndSettle();

      expect(find.text('ORDEN #105'), findsNothing);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await _pumpOrdenes(tester, ancho: 320);

      expect(tester.takeException(), isNull);
    });
  });

  group('Detalle de Orden', () {
    Future<TestEnv> pumpDetalle(
      WidgetTester tester,
      Orden orden, {
      double ancho = 420,
    }) async {
      setScreenSize(tester, ancho, 1800);
      final env = TestEnv()..iniciarSesionComoClienteConOrdenes([orden]);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) =>
                env.detalleOrdenBloc(orden.id)..add(DetalleOrdenStarted()),
            child: DetalleOrdenPage(ahora: () => ahoraSeguimiento),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('muestra la tienda, el código, el estado y los productos',
        (tester) async {
      await pumpDetalle(tester, ordenSeguimiento());

      expect(find.text('#105'), findsOneWidget);
      expect(find.text('LISTO PARA RECOGER'), findsOneWidget);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Carrera 15 # 124-30, Bogotá'), findsOneWidget);
      expect(find.text('CÓDIGO DE RECOGIDA'), findsOneWidget);
      expect(find.text('SC-105'), findsOneWidget);
      expect(find.text('Confirmar recogida'), findsOneWidget);
      expect(find.text('ESTADO DEL PEDIDO'), findsOneWidget);
      // Último cambio: 9:15 + 3 × 15 min = 10:00; ahora son las 11:00.
      expect(find.text('Actualizado hace 1 h'), findsOneWidget);
      expect(find.text('Orden generada'), findsOneWidget);
      expect(find.text('9:15 AM'), findsOneWidget);
      expect(find.text('Lista para recoger'), findsOneWidget);
      expect(find.text('RESUMEN DE PRODUCTOS'), findsOneWidget);
      expect(find.text('4 artículos'), findsOneWidget);
      expect(find.text('Arroz Blanco Premium 1kg'), findsOneWidget);
      expect(find.text('Total pagado'), findsOneWidget);
      expect(find.text(r'$ 17.100'), findsOneWidget);
    });

    testWidgets('una entrega en camino aún no se puede confirmar',
        (tester) async {
      await pumpDetalle(
        tester,
        ordenSeguimiento(estado: EstadoOrden.enCamino, tipo: TipoEntrega.entrega),
      );

      expect(find.text('ENTREGA A DOMICILIO'), findsOneWidget);
      expect(find.text('Calle 80 # 10-20'), findsOneWidget);
      expect(find.text('SC-105'), findsNothing);
      final boton =
          tester.widget<FilledButton>(find.byKey(const Key('boton-confirmar')));
      expect(boton.onPressed, isNull);
      expect(
        find.text('Podrás confirmarla cuando el repartidor la entregue.'),
        findsOneWidget,
      );
    });

    testWidgets('escenario 2: confirmar la recepción de una entrega',
        (tester) async {
      final env = await pumpDetalle(
        tester,
        ordenSeguimiento(estado: EstadoOrden.entregada, tipo: TipoEntrega.entrega),
      );

      await _ver(tester, find.text('Confirmar recepción'));
      await tester.tap(find.text('Confirmar recepción'));
      await tester.pumpAndSettle();

      expect(env.seg.seguimiento.confirmadas, ['o105']);
      expect(find.textContaining('Confirmaste la recepción'), findsOneWidget);
    });

    testWidgets('si la orden no carga deja reintentar', (tester) async {
      setScreenSize(tester, 420, 900);
      final env = TestEnv()..iniciarSesionComoClienteConOrdenes();
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider(
          create: (_) => env.detalleOrdenBloc('nada')..add(DetalleOrdenStarted()),
          child: DetalleOrdenPage(ahora: () => ahoraSeguimiento),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No encontramos esa orden.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('en 320 px no hay desbordes', (tester) async {
      await pumpDetalle(tester, ordenSeguimiento(), ancho: 320);

      expect(tester.takeException(), isNull);
    });
  });

  group('Avisos push en el Home del cliente', () {
    Future<TestEnv> pumpHome(WidgetTester tester) async {
      setScreenSize(tester, 420, 900);
      final env = TestEnv()..iniciarSesionComoClienteConOrdenes(_ordenes());
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: stubRoutes,
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => env.notificacionesBloc()),
              BlocProvider(create: (_) => env.pushBloc()..add(PushIniciado())),
            ],
            child: const AvisoNotificaciones(
              child: AvisosPush(child: Scaffold(body: Text('HOME CLIENTE'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return env;
    }

    testWidgets('al entrar activa el push y guarda el token', (tester) async {
      final env = await pumpHome(tester);

      expect(env.seg.dispositivos.registrados.single.token,
          'token-fcm-de-prueba');
    });

    testWidgets(
        'escenario 1: un aviso con la app abierta se ve dentro de la app',
        (tester) async {
      final env = await pumpHome(tester);
      // El trigger de la base ya guardó el aviso (HU-24).
      env.notificaciones.noLeidasList.add(Notificacion(
        id: 'n1',
        titulo: '¡Tu orden #105 está lista para recoger!',
        mensaje: 'Acércate a Minimercado La Esquina y muestra tu código.',
        creadoEn: ahoraSeguimiento,
      ));

      env.seg.push.primerPlano.add(const AvisoPush(
        titulo: '¡Tu orden #105 está lista para recoger!',
        mensaje: 'Acércate a Minimercado La Esquina y muestra tu código.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('¡Tu orden #105 está lista para recoger!'),
          findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(env.notificaciones.marcadas, ['n1']);
    });

    testWidgets('tocar la notificación del sistema abre "Mis órdenes"',
        (tester) async {
      final env = await pumpHome(tester);

      env.seg.push.abiertos.add(null);
      await tester.pumpAndSettle();

      expect(find.text('MIS ORDENES'), findsOneWidget);
    });
  });
}
