import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/estadisticas/data/source/supabase_estadisticas_data_source.dart';
import 'package:smartcart/features/estadisticas/presentation/bloc/estadisticas_bloc.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';

import '../support/fakes.dart';
import '../support/fakes_estadisticas.dart';

void main() {
  group('respuesta de estadisticas_panel', () {
    test('convierte cada cifra del JSON', () {
      final e = SupabaseEstadisticasDataSource.desdeJson({
        'usuarios_por_rol': {'cliente': 12, 'administrador': 1},
        'comercios_por_estado': {'aprobado': 3, 'pendiente': 1},
        'repartidores_aprobados': 6,
        'repartidores_en_linea': 4,
        'solicitudes_comercio': 1,
        'solicitudes_repartidor': 2,
        'reportes_precio_pendientes': 7,
        'ordenes': {
          'hoy': 2,
          'por_estado': {'generada': 5, 'lista_para_recoger': 1},
        },
      });

      expect(e.usuariosDe(UserRole.cliente), 12);
      expect(e.usuariosDe(UserRole.colaborador), 0);
      expect(e.comerciosEn(ApprovalStatus.aprobado), 3);
      expect(e.comerciosEn(ApprovalStatus.rechazado), 0);
      expect(e.repartidoresAprobados, 6);
      expect(e.repartidoresEnLinea, 4);
      expect(e.solicitudesPendientes, 3);
      expect(e.reportesPrecioPendientes, 7);
      expect(e.ordenes!.hoy, 2);
      expect(e.ordenes!.de(EstadoOrden.generada), 5);
      expect(e.ordenes!.de(EstadoOrden.listaParaRecoger), 1);
      expect(e.ordenes!.de(EstadoOrden.rechazada), 0);
    });

    test('escenario 3: sin órdenes no hay cifras de órdenes', () {
      final e = SupabaseEstadisticasDataSource.desdeJson({'ordenes': null});

      expect(e.ordenes, isNull);
      expect(e.solicitudesPendientes, 0);
    });
  });

  group('GetEstadisticasUseCase', () {
    late TestEnv env;

    setUp(() => env = TestEnv()..iniciarSesionCon({UserRole.administrador}));

    test('el administrador recibe las cifras', () async {
      final e = await env.getEstadisticas();

      expect(e.comerciosEn(ApprovalStatus.aprobado), 3);
      expect(env.estadisticas.llamadas, 1);
    });

    test('escenario 4: los demás perfiles se rechazan sin consultar la base',
        () async {
      for (final rol
          in UserRole.values.where((r) => r != UserRole.administrador)) {
        env.iniciarSesionCon({rol});

        await expectLater(
          env.getEstadisticas(),
          throwsA(isA<AuthFailure>().having(
              (f) => f.message, 'mensaje', contains('Solo el administrador'))),
        );
      }
      expect(env.estadisticas.llamadas, 0);
    });

    test('sin sesión no se consulta', () async {
      env.auth.current = null;

      await expectLater(env.getEstadisticas(), throwsA(isA<AuthFailure>()));
      expect(env.estadisticas.llamadas, 0);
    });
  });

  group('EstadisticasBloc', () {
    late TestEnv env;
    late EstadisticasBloc bloc;

    Future<EstadisticasState> hasta(EstadisticasStatus status) =>
        bloc.stream.firstWhere((s) => s.status == status);

    setUp(() {
      env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      bloc = env.estadisticasBloc();
    });

    tearDown(() => bloc.close());

    test('carga y entrega las cifras', () async {
      final estados = <EstadisticasStatus>[];
      final sub = bloc.stream.listen((s) => estados.add(s.status));

      bloc.add(EstadisticasSolicitadas());
      final lista = await hasta(EstadisticasStatus.lista);
      await sub.cancel();

      expect(estados,
          [EstadisticasStatus.cargando, EstadisticasStatus.lista]);
      expect(lista.datos!.solicitudesPendientes, 3);
    });

    test('al volver a consultar conserva las cifras mientras carga y luego las '
        'actualiza', () async {
      bloc.add(EstadisticasSolicitadas());
      await hasta(EstadisticasStatus.lista);

      env.estadisticas.datos = cifras(aprobados: 4, pendientes: 0);
      final cargando = hasta(EstadisticasStatus.cargando);
      bloc.add(EstadisticasSolicitadas());
      expect((await cargando).datos!.comerciosEn(ApprovalStatus.aprobado), 3);

      final lista = await hasta(EstadisticasStatus.lista);
      expect(lista.datos!.comerciosEn(ApprovalStatus.aprobado), 4);
      expect(lista.datos!.comerciosEn(ApprovalStatus.pendiente), 0);
    });

    test('una respuesta atrasada no pisa la más reciente', () async {
      final primera = Completer<void>();
      env.estadisticas.gate = primera;
      bloc.add(EstadisticasSolicitadas());
      await Future<void>.delayed(Duration.zero);

      env.estadisticas.datos = cifras(aprobados: 9);
      bloc.add(EstadisticasSolicitadas());
      await hasta(EstadisticasStatus.lista);

      primera.complete();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.datos!.comerciosEn(ApprovalStatus.aprobado), 9);
    });

    test('si falla deja el mensaje, sin cifras viejas, y se puede reintentar',
        () async {
      bloc.add(EstadisticasSolicitadas());
      await hasta(EstadisticasStatus.lista);

      env.estadisticas.error = const AuthFailure('Sin conexión.');
      bloc.add(EstadisticasSolicitadas());
      final fallo = await hasta(EstadisticasStatus.fallida);
      expect(fallo.errorMessage, 'Sin conexión.');
      expect(fallo.datos, isNull);

      env.estadisticas.error = null;
      bloc.add(EstadisticasSolicitadas());
      await hasta(EstadisticasStatus.lista);
    });

    test('un error inesperado se muestra con un mensaje genérico', () async {
      env.estadisticas.error = StateError('x');

      bloc.add(EstadisticasSolicitadas());
      final fallo = await hasta(EstadisticasStatus.fallida);

      expect(fallo.errorMessage, contains('No pudimos cargar'));
    });
  });
}
