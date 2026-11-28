import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/seguimiento/domain/notificaciones_push.dart';
import 'package:smartcart/features/seguimiento/domain/seguimiento_reglas.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/detalle_orden_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/ordenes_cliente_bloc.dart';
import 'package:smartcart/features/seguimiento/presentation/bloc/push_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_seguimiento.dart';

Matcher _falla([String? contiene]) => throwsA(
      isA<AuthFailure>().having(
        (e) => e.message,
        'message',
        contiene == null ? isNotEmpty : contains(contiene),
      ),
    );

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()
      ..iniciarSesionComoClienteConOrdenes([
        ordenSeguimiento(),
        ordenSeguimiento(
          id: 'o102',
          numero: 102,
          estado: EstadoOrden.enPreparacion,
          tipo: TipoEntrega.entrega,
        ),
        ordenSeguimiento(
          id: 'o90',
          numero: 90,
          estado: EstadoOrden.recogida,
          cerradaEn: DateTime(2026, 11, 20),
        ),
      ]);
  });

  group('SeguimientoReglas', () {
    test('los pasos dependen del tipo de entrega', () {
      expect(
        [for (final p in SeguimientoReglas.pasos(TipoEntrega.recogida)) p.etiqueta],
        ['PREPARANDO', 'LISTO', 'RECOGIDA'],
      );
      expect(
        [for (final p in SeguimientoReglas.pasos(TipoEntrega.entrega)) p.etiqueta],
        ['PREPARANDO', 'LISTO', 'EN CAMINO', 'ENTREGADA'],
      );
    });

    test('el progreso avanza con el estado', () {
      double p(EstadoOrden e, [TipoEntrega t = TipoEntrega.recogida]) =>
          SeguimientoReglas.progreso(ordenSeguimiento(estado: e, tipo: t));

      expect(p(EstadoOrden.generada), 0);
      expect(p(EstadoOrden.aceptada), greaterThan(0));
      expect(p(EstadoOrden.enPreparacion), closeTo(1 / 3, 0.001));
      expect(p(EstadoOrden.listaParaRecoger), closeTo(2 / 3, 0.001));
      expect(p(EstadoOrden.recogida), 1);
      expect(p(EstadoOrden.enCamino, TipoEntrega.entrega), 0.75);
      expect(p(EstadoOrden.rechazada), 0);
    });

    test('escenario 2: cuándo se puede confirmar', () {
      bool puede(EstadoOrden e, TipoEntrega t, {DateTime? cerrada}) =>
          SeguimientoReglas.puedeConfirmar(
              ordenSeguimiento(estado: e, tipo: t, cerradaEn: cerrada));

      expect(puede(EstadoOrden.listaParaRecoger, TipoEntrega.recogida), isTrue);
      expect(puede(EstadoOrden.recogida, TipoEntrega.recogida), isTrue);
      expect(puede(EstadoOrden.enPreparacion, TipoEntrega.recogida), isFalse);
      expect(puede(EstadoOrden.entregada, TipoEntrega.entrega), isTrue);
      expect(puede(EstadoOrden.enCamino, TipoEntrega.entrega), isFalse);
      // La entrega no se "recoge": el repartidor la lleva.
      expect(puede(EstadoOrden.listaParaRecoger, TipoEntrega.entrega), isFalse);
      expect(
        puede(EstadoOrden.entregada, TipoEntrega.entrega,
            cerrada: DateTime(2026)),
        isFalse,
      );
    });

    test('código de recogida y textos', () {
      expect(SeguimientoReglas.codigoRecogida(105), 'SC-105');
      expect(SeguimientoReglas.textoConfirmar(TipoEntrega.recogida),
          'Confirmar recogida');
      expect(SeguimientoReglas.textoConfirmar(TipoEntrega.entrega),
          'Confirmar recepción');
      expect(SeguimientoReglas.listaParaRecoger(ordenSeguimiento()), isTrue);
      expect(
        SeguimientoReglas.listaParaRecoger(
            ordenSeguimiento(tipo: TipoEntrega.entrega)),
        isFalse,
      );
    });
  });

  group('Casos de uso', () {
    test('separa "En curso" del "Historial"', () async {
      final enCurso = await env.getOrdenesCliente(
          enCurso: true, request: const PageRequest());
      final historial = await env.getOrdenesCliente(
          enCurso: false, request: const PageRequest());

      expect([for (final o in enCurso.items) o.numero], [105, 102]);
      expect([for (final o in historial.items) o.numero], [90]);
      expect(await env.contarOrdenesEnCurso(), 2);
    });

    test('solo un cliente ve sus órdenes', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(
        env.getOrdenesCliente(enCurso: true, request: const PageRequest()),
        _falla('cliente'),
      );
    });

    test('el detalle trae productos e historial', () async {
      final detalle = await env.getDetalleOrden('o105');

      expect(detalle.items, hasLength(3));
      expect(detalle.unidades, 4);
      expect(detalle.historial.last.estado, EstadoOrden.listaParaRecoger);
    });

    test('una orden que no existe lo dice', () async {
      await expectLater(env.getDetalleOrden('nada'), _falla('No encontramos'));
    });

    test('escenario 2: confirmar la recogida cierra la orden', () async {
      final detalle = await env.getDetalleOrden('o105');

      final cerrado = await env.confirmarRecepcion(detalle);

      expect(cerrado.orden.cerradaEn, isNotNull);
      expect(cerrado.orden.estado, EstadoOrden.recogida);
      expect(env.seg.seguimiento.confirmadas, ['o105']);
      expect(await env.contarOrdenesEnCurso(), 1);
    });

    test('no se confirma una orden que aún no está lista', () async {
      final detalle = await env.getDetalleOrden('o102');

      await expectLater(env.confirmarRecepcion(detalle), _falla('Todavía no'));
      expect(env.seg.seguimiento.confirmadas, isEmpty);
    });

    test('el mensaje de la base llega tal cual', () async {
      env.seg.seguimiento.confirmarError =
          const AuthFailure('Ya confirmaste esta orden.');
      final detalle = await env.getDetalleOrden('o105');

      await expectLater(env.confirmarRecepcion(detalle), _falla('Ya confirmaste'));
    });

    test('activar el push guarda el token del teléfono', () async {
      expect(await env.activarPush(), isTrue);

      expect(env.seg.dispositivos.registrados.single.token,
          'token-fcm-de-prueba');
      expect(env.seg.dispositivos.registrados.single.plataforma, 'android');
    });

    test('sin permiso o sin Firebase el push queda apagado, sin error',
        () async {
      env.seg.push.token = null;

      expect(await env.activarPush(), isFalse);
      expect(env.seg.dispositivos.registrados, isEmpty);
    });

    test('sin sesión no se activa el push', () async {
      env.auth.current = null;

      expect(await env.activarPush(), isFalse);
      expect(env.seg.push.activaciones, 0);
    });
  });

  group('OrdenesClienteBloc', () {
    Future<PaginatedState<dynamic>> listo(OrdenesClienteBloc bloc) =>
        bloc.stream.firstWhere((s) => s.status == PaginatedStatus.success);

    test('arranca en "En curso" y cambia al "Historial"', () async {
      final bloc = env.ordenesClienteBloc()..add(PaginatedStarted());
      expect((await listo(bloc)).items, hasLength(2));

      bloc.add(PestanaOrdenesCambiada(enCurso: false));
      final state = await bloc.stream.firstWhere(
          (s) => s.status == PaginatedStatus.success && s.items.length == 1);

      expect(state.items.single.numero, 90);
      expect(bloc.enCurso, isFalse);
      await bloc.close();
    });

    test('escenario 3: sin órdenes la lista queda vacía', () async {
      final vacio = TestEnv()..iniciarSesionComoClienteConOrdenes();
      final bloc = vacio.ordenesClienteBloc()..add(PaginatedStarted());

      expect((await listo(bloc)).isEmpty, isTrue);
      expect(SeguimientoReglas.mensajeSinOrdenes, 'Aún no tienes órdenes');
      await bloc.close();
    });

    test('el conteo de órdenes en curso', () async {
      final bloc = env.conteoOrdenesBloc()..add(ConteoOrdenesPedido());

      expect(await bloc.stream.first, 2);
      await bloc.close();
    });
  });

  group('DetalleOrdenBloc', () {
    test('carga y confirma una sola vez aunque se toque dos veces', () async {
      final bloc = env.detalleOrdenBloc('o105')..add(DetalleOrdenStarted());
      await bloc.stream.firstWhere((s) => s.status == DetalleOrdenStatus.ready);

      bloc
        ..add(RecepcionConfirmada())
        ..add(RecepcionConfirmada());
      final state = await bloc.stream.firstWhere((s) => s.aviso != null);

      expect(state.detalle?.orden.cerradaEn, isNotNull);
      expect(state.huboCambios, isTrue);
      expect(state.aviso?.esError, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(env.seg.seguimiento.confirmadas, ['o105']);
      await bloc.close();
    });

    test('un error al confirmar se avisa y la orden sigue abierta', () async {
      env.seg.seguimiento.confirmarError = const AuthFailure('Sin conexión.');
      final bloc = env.detalleOrdenBloc('o105')..add(DetalleOrdenStarted());
      await bloc.stream.firstWhere((s) => s.status == DetalleOrdenStatus.ready);

      bloc.add(RecepcionConfirmada());
      final state = await bloc.stream.firstWhere((s) => s.aviso != null);

      expect(state.aviso?.texto, 'Sin conexión.');
      expect(state.aviso?.esError, isTrue);
      expect(state.detalle?.orden.cerradaEn, isNull);
      await bloc.close();
    });

    test('si no carga deja reintentar', () async {
      final bloc = env.detalleOrdenBloc('nada')..add(DetalleOrdenStarted());

      final state =
          await bloc.stream.firstWhere((s) => s.status == DetalleOrdenStatus.failed);

      expect(state.errorMessage, contains('No encontramos'));
      await bloc.close();
    });
  });

  group('PushBloc', () {
    test('al iniciar activa el push', () async {
      final bloc = env.pushBloc()..add(PushIniciado());

      final state = await bloc.stream.firstWhere((s) => s.activas);

      expect(state.activas, isTrue);
      await bloc.close();
    });

    test('escenario 1: un aviso con la app abierta se pasa a la pantalla',
        () async {
      final bloc = env.pushBloc()..add(PushIniciado());
      await bloc.stream.firstWhere((s) => s.activas);

      env.seg.push.primerPlano.add(const AvisoPush(
        titulo: '¡Tu orden #105 está lista para recoger!',
        mensaje: 'Acércate a Minimercado La Esquina.',
      ));
      final state = await bloc.stream.firstWhere((s) => s.numeroAviso == 1);

      expect(state.aviso?.titulo, contains('lista para recoger'));
      await bloc.close();
    });

    test('tocar un aviso pide abrir "Mis órdenes"', () async {
      final bloc = env.pushBloc()..add(PushIniciado());
      await bloc.stream.firstWhere((s) => s.activas);

      env.seg.push.abiertos.add(null);
      final state = await bloc.stream.firstWhere((s) => s.abrirOrdenes == 1);

      expect(state.abrirOrdenes, 1);
      await bloc.close();
    });

    test('si Firebase renueva el token, se guarda el nuevo', () async {
      final bloc = env.pushBloc()..add(PushIniciado());
      await bloc.stream.firstWhere((s) => s.activas);

      env.seg.push.renovados.add('token-nuevo-de-prueba');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(env.seg.dispositivos.registrados.last.token, 'token-nuevo-de-prueba');
      await bloc.close();
    });
  });
}
