import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/presentation/pages/carrito_page.dart';
import 'package:smartcart/features/cliente/presentation/cliente_blocs.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/presentation/bloc/confirmar_compra_bloc.dart';
import 'package:smartcart/features/orders/presentation/pages/confirmar_compra_page.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';
import '../support/fakes_ordenes.dart';
import '../support/pump_helpers.dart';

/// Espera a que el Bloc llegue a [status].
Future<ConfirmarCompraState> _hasta(
  ConfirmarCompraBloc bloc,
  ConfirmarCompraStatus status,
) =>
    bloc.stream.firstWhere((s) => s.status == status);

Future<(TestEnv, ConfirmarCompraBloc, ClienteBlocs)> _pump(
  WidgetTester tester, {
  Map<String, int> carrito = const {'p1': 2, 'p2': 1, 'p3': 1},
  void Function(TestEnv env)? prepare,
}) async {
  setScreenSize(tester, 420, 1200);
  final env = TestEnv()..iniciarSesionComoClienteConCompras();
  env.llenarCarrito(carrito);
  prepare?.call(env);
  final blocs = env.clienteBlocs();
  final bloc = env.confirmarCompraBloc()..add(ConfirmarCompraStarted());
  addTearDown(() async {
    await blocs.cerrar();
    await bloc.close();
  });

  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: stubRoutes,
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: blocs.carrito),
          BlocProvider.value(value: blocs.favoritos),
          BlocProvider.value(value: bloc),
        ],
        child: const ConfirmarCompraPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (env, bloc, blocs);
}

void main() {
  group('ConfirmarCompraBloc', () {
    test('al abrir arma el plan y deja recogida en cada comercio', () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.llenarCarrito({'p1': 1, 'p3': 1});
      final bloc = env.confirmarCompraBloc()..add(ConfirmarCompraStarted());

      final state = await _hasta(bloc, ConfirmarCompraStatus.listo);

      expect(state.plan!.registrados.length, 2);
      expect(state.elecciones.keys, unorderedEquals(['c1', 'c2']));
      expect(state.elecciones.values.every((e) => e.tipo == TipoEntrega.recogida),
          isTrue);
      expect(state.puedeConfirmar, isTrue);
      await bloc.close();
    });

    test('con el carrito vacío falla con el mensaje', () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      final bloc = env.confirmarCompraBloc()..add(ConfirmarCompraStarted());

      final state = await _hasta(bloc, ConfirmarCompraStatus.falloCarga);

      expect(state.errorMessage, contains('carrito está vacío'));
      await bloc.close();
    });

    test('elegir entrega exige dirección; escribirla habilita confirmar',
        () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.llenarCarrito({'p1': 1});
      final bloc = env.confirmarCompraBloc()..add(ConfirmarCompraStarted());
      await _hasta(bloc, ConfirmarCompraStatus.listo);

      bloc.add(EntregaElegida('c1', TipoEntrega.entrega));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.puedeConfirmar, isFalse);
      expect(bloc.state.motivoBloqueo, contains('dirección de entrega'));

      bloc.add(DireccionCambiada('c1', 'Calle 10 # 5-20'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.puedeConfirmar, isTrue);

      // Volver a recogida no pide dirección y al regresar a entrega se
      // conserva la que ya estaba escrita.
      bloc.add(EntregaElegida('c1', TipoEntrega.recogida));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.puedeConfirmar, isTrue);
      bloc.add(EntregaElegida('c1', TipoEntrega.entrega));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.elecciones['c1']!.direccion, 'Calle 10 # 5-20');
      await bloc.close();
    });

    test('confirmar dos veces seguidas genera una sola compra', () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.llenarCarrito({'p1': 1});
      final bloc = env.confirmarCompraBloc()..add(ConfirmarCompraStarted());
      await _hasta(bloc, ConfirmarCompraStatus.listo);

      bloc
        ..add(CompraConfirmada())
        ..add(CompraConfirmada());
      await _hasta(bloc, ConfirmarCompraStatus.exito);

      expect(env.ordenes.compras.confirmarCalls, 1);
      expect(env.ordenes.compras.ordenes.length, 1);
      await bloc.close();
    });

    test('si la base rechaza, vuelve a "listo" con un aviso de error',
        () async {
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.llenarCarrito({'p1': 1});
      env.ordenes.compras.confirmarError =
          const AuthFailure('Uno de los productos ya no está disponible.');
      final bloc = env.confirmarCompraBloc()..add(ConfirmarCompraStarted());
      await _hasta(bloc, ConfirmarCompraStatus.listo);

      bloc.add(CompraConfirmada());
      final state = await bloc.stream.firstWhere((s) => s.aviso != null);

      expect(state.status, ConfirmarCompraStatus.listo);
      expect(state.aviso!.esError, isTrue);
      expect(state.aviso!.texto, contains('ya no está disponible'));
      expect(state.comprobante, isNull);
      await bloc.close();
    });
  });

  group('ConfirmarCompraPage', () {
    testWidgets('muestra cada comercio con sus productos, subtotal y total',
        (tester) async {
      await _pump(tester);

      expect(find.text('Confirmar compra'), findsWidgets);
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(find.text('2 × Arroz blanco 500 g'), findsOneWidget);
      expect(find.text('Subtotal \$ 10.500'), findsOneWidget);
      expect(find.text('Subtotal \$ 12.000'), findsOneWidget);
      expect(find.text('\$ 22.500'), findsOneWidget);
    });

    testWidgets('la entrega solo se ofrece en el comercio que la tiene',
        (tester) async {
      await _pump(tester);

      // La Esquina ofrece ambos; Doña Rosa solo recogida.
      expect(find.text('Recogida en tienda'), findsNWidgets(2));
      expect(find.text('Entrega a domicilio'), findsOneWidget);
      expect(find.text('Este comercio solo ofrece recogida en tienda.'),
          findsOneWidget);
    });

    testWidgets('con recogida en todos se puede confirmar', (tester) async {
      await _pump(tester);

      final boton = tester.widget<FilledButton>(find.widgetWithText(
          FilledButton, 'Confirmar compra'));
      expect(boton.onPressed, isNotNull);
    });

    testWidgets('elegir entrega pide la dirección y bloquea hasta escribirla',
        (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Entrega a domicilio'));
      await tester.pumpAndSettle();

      expect(find.text('Dirección de entrega'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmar compra'))
            .onPressed,
        isNull,
      );
      expect(find.text('Escribe la dirección de entrega para Minimercado La Esquina.'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Calle 10 # 5-20');
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmar compra'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
        'confirmar genera una orden por comercio "Orden generada" y vacía el carrito',
        (tester) async {
      final (env, _, blocs) = await _pump(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Compra confirmada'), findsOneWidget);
      expect(find.text('Se generaron 2 órdenes'), findsOneWidget);
      expect(find.text('Orden generada'), findsNWidgets(2));
      expect(find.text('Minimercado La Esquina'), findsOneWidget);
      expect(find.text('Tienda Doña Rosa'), findsOneWidget);
      expect(env.ordenes.compras.ordenes.length, 2);

      // La compra sacó los productos del carrito y el CarritoBloc se releyó.
      expect(env.cliente.carrito.lineas, isEmpty);
      expect(blocs.carrito.state.vacio, isTrue);
    });

    testWidgets('un establecimiento sin registro recibe su lista de compra',
        (tester) async {
      await _pump(
        tester,
        carrito: {'p1': 1, 'p3': 2},
        prepare: (env) => env.ordenes.compras.catalogo['p3'] = const LineaPrevia(
          establecimiento: 'Plaza de mercado',
          linea: LineaCompra(
              idProducto: 'p3',
              nombre: 'Café molido 500 g',
              cantidad: 1,
              precioUnitario: 12000),
        ),
      );

      expect(find.textContaining('no está registrado en SmartCart'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Se generó 1 orden'), findsOneWidget);
      expect(find.text('Lista de compra · Plaza de mercado'), findsOneWidget);
      expect(find.text('• 2 × Café molido 500 g'), findsOneWidget);
    });

    testWidgets('si la base rechaza se queda en la pantalla y explica',
        (tester) async {
      await _pump(
        tester,
        prepare: (env) => env.ordenes.compras.confirmarError =
            const AuthFailure('Uno de los productos ya no está disponible.'),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.text('Uno de los productos ya no está disponible.'),
          findsOneWidget);
      expect(find.text('Compra confirmada'), findsNothing);
      expect(find.text('Confirmar compra'), findsWidgets);
    });

    testWidgets('con el carrito vacío no se puede confirmar y deja reintentar',
        (tester) async {
      await _pump(tester, carrito: const {});

      expect(find.textContaining('carrito está vacío'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Confirmar compra'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('producto agotado: se marca y no deja confirmar',
        (tester) async {
      await _pump(
        tester,
        carrito: {'p1': 1},
        prepare: (env) {
          final previa = env.ordenes.compras.catalogo['p1']!;
          env.ordenes.compras.catalogo['p1'] = LineaPrevia(
            idComercio: previa.idComercio,
            establecimiento: previa.establecimiento,
            servicio: previa.servicio,
            linea: const LineaCompra(
              idProducto: 'p1',
              nombre: 'Arroz blanco 500 g',
              cantidad: 1,
              precioUnitario: 3000,
              disponible: false,
            ),
          );
        },
      );

      expect(find.text('No disponible'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmar compra'))
            .onPressed,
        isNull,
      );
    });
  });

  group('CarritoPage → confirmar', () {
    testWidgets('el carrito con productos ofrece "Confirmar compra"',
        (tester) async {
      setScreenSize(tester, 420, 1200);
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      env.llenarCarrito({'p1': 1});
      final blocs = env.clienteBlocs();
      addTearDown(blocs.cerrar);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: stubRoutes,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: blocs.carrito),
              BlocProvider.value(value: blocs.favoritos),
            ],
            child: const CarritoPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmar compra'), findsOneWidget);
    });

    testWidgets('el carrito vacío no ofrece confirmar', (tester) async {
      setScreenSize(tester, 420, 900);
      final env = TestEnv()..iniciarSesionComoClienteConCompras();
      final blocs = env.clienteBlocs();
      addTearDown(blocs.cerrar);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: stubRoutes,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: blocs.carrito),
              BlocProvider.value(value: blocs.favoritos),
            ],
            child: const CarritoPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmar compra'), findsNothing);
    });
  });
}
