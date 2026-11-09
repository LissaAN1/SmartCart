import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/validators/aprobacion_validators.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_event.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_state.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

import '../support/fakes.dart';

const _motivo = 'La dirección registrada no existe.';

void main() {
  group('AprobacionValidators.motivoRechazo', () {
    test('exige el motivo', () {
      expect(AprobacionValidators.motivoRechazo(null), isNotNull);
      expect(AprobacionValidators.motivoRechazo(''), isNotNull);
      expect(AprobacionValidators.motivoRechazo('    '), isNotNull);
    });

    test('pide un motivo con algo de detalle', () {
      expect(AprobacionValidators.motivoRechazo('no'), isNotNull);
    });

    test('no acepta un motivo demasiado largo', () {
      expect(AprobacionValidators.motivoRechazo('a' * 301), isNotNull);
    });

    test('acepta un motivo claro', () {
      expect(AprobacionValidators.motivoRechazo(_motivo), isNull);
    });
  });

  group('DecidirSolicitudUseCase · escenario 1: aprobar', () {
    test('el administrador aprueba un comercio pendiente', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      final solicitud = solicitudComercio();
      env.solicitudes.pendientesPorTipo[TipoSolicitud.comercio]!.add(solicitud);

      await env.decidirSolicitud.aprobar(solicitud);

      expect(env.solicitudes.decisiones, hasLength(1));
      final decision = env.solicitudes.decisiones.single;
      expect(decision.solicitud, same(solicitud));
      expect(decision.aprobar, isTrue);
      expect(decision.motivo, isNull);
      // Ya no está pendiente.
      expect(
          env.solicitudes.pendientesPorTipo[TipoSolicitud.comercio], isEmpty);
    });

    test('también aprueba un repartidor', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});

      await env.decidirSolicitud.aprobar(solicitudRepartidor());

      expect(env.solicitudes.decisiones.single.solicitud.tipo,
          TipoSolicitud.repartidor);
    });
  });

  group('DecidirSolicitudUseCase · escenario 2: rechazar', () {
    test('sin motivo no rechaza y pide el motivo', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});

      await expectLater(
        env.decidirSolicitud.rechazar(solicitudComercio(), motivo: '  '),
        throwsA(isA<AuthFailure>().having(
            (f) => f.message, 'message', 'Escribe el motivo del rechazo.')),
      );
      expect(env.solicitudes.decisiones, isEmpty);
    });

    test('con motivo rechaza y envía el motivo sin espacios de más', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});

      await env.decidirSolicitud
          .rechazar(solicitudRepartidor(), motivo: '  $_motivo  ');

      final decision = env.solicitudes.decisiones.single;
      expect(decision.aprobar, isFalse);
      expect(decision.motivo, _motivo);
    });
  });

  group('DecidirSolicitudUseCase · escenario 3: sin permiso', () {
    for (final rol
        in UserRole.values.where((r) => r != UserRole.administrador)) {
      test('una cuenta ${rol.label} no puede aprobar', () async {
        final env = TestEnv()..iniciarSesionCon({rol});

        await expectLater(
          env.decidirSolicitud.aprobar(solicitudComercio()),
          throwsA(isA<AuthFailure>()),
        );
        expect(env.solicitudes.decisiones, isEmpty);
      });
    }

    test('sin sesión no se puede decidir', () async {
      final env = TestEnv();

      await expectLater(
        env.decidirSolicitud.rechazar(solicitudComercio(), motivo: _motivo),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.solicitudes.decisiones, isEmpty);
    });

    test('si la base rechaza por permisos, el error llega tal cual', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      env.solicitudes.decidirError =
          const AuthFailure('No tienes permiso para realizar esta acción.');

      await expectLater(
        env.decidirSolicitud.aprobar(solicitudComercio()),
        throwsA(isA<AuthFailure>().having((f) => f.message, 'message',
            'No tienes permiso para realizar esta acción.')),
      );
    });
  });

  group('DecisionSolicitudBloc', () {
    test('aprobar termina en éxito con la decisión aprobada', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      final bloc = env.decisionBloc(solicitudComercio());
      final estados = <DecisionSolicitudStatus>[];
      final sub = bloc.stream.listen((s) => estados.add(s.status));

      bloc.add(AprobacionSolicitada());
      await bloc.stream
          .firstWhere((s) => s.status == DecisionSolicitudStatus.success);

      expect(estados, [
        DecisionSolicitudStatus.loading,
        DecisionSolicitudStatus.success,
      ]);
      expect(bloc.state.decision, ApprovalStatus.aprobado);
      await sub.cancel();
      await bloc.close();
    });

    test('rechazar sin motivo muestra el error y no decide', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      final bloc = env.decisionBloc(solicitudComercio());

      bloc.add(RechazoSolicitado(''));
      final estado = await bloc.stream
          .firstWhere((s) => s.status == DecisionSolicitudStatus.failure);

      expect(estado.errorMessage, 'Escribe el motivo del rechazo.');
      expect(env.solicitudes.decisiones, isEmpty);
      await bloc.close();
    });

    test('rechazar con motivo termina con la decisión rechazada', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      final bloc = env.decisionBloc(solicitudRepartidor());

      bloc.add(RechazoSolicitado(_motivo));
      await bloc.stream
          .firstWhere((s) => s.status == DecisionSolicitudStatus.success);

      expect(bloc.state.decision, ApprovalStatus.rechazado);
      expect(env.solicitudes.decisiones.single.motivo, _motivo);
      await bloc.close();
    });

    test('un doble toque no decide dos veces', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.administrador});
      final bloc = env.decisionBloc(solicitudComercio());

      bloc
        ..add(AprobacionSolicitada())
        ..add(AprobacionSolicitada());
      await bloc.stream
          .firstWhere((s) => s.status == DecisionSolicitudStatus.success);
      await Future<void>.delayed(Duration.zero);

      expect(env.solicitudes.decisiones, hasLength(1));
      await bloc.close();
    });
  });

  group('Lista de pendientes por páginas', () {
    test('pide cada tipo por separado y por páginas', () async {
      final env = TestEnv();
      env.solicitudes.pendientesPorTipo[TipoSolicitud.comercio]!.addAll([
        for (var i = 0; i < 5; i++)
          solicitudComercio(id: 'c$i', nombre: 'Comercio $i'),
      ]);
      final bloc = env.listaBloc(TipoSolicitud.comercio, pageSize: 2);

      bloc.add(PaginatedStarted());
      await bloc.stream.firstWhere((s) => s.status == PaginatedStatus.success);
      expect(bloc.state.items.map((s) => s.id), ['c0', 'c1']);
      expect(bloc.state.hasMore, isTrue);

      bloc.add(NextPageRequested());
      await bloc.stream.firstWhere((s) => s.items.length == 4);
      bloc.add(NextPageRequested());
      await bloc.stream.firstWhere((s) => s.items.length == 5);

      expect(bloc.state.hasMore, isFalse);
      expect(env.solicitudes.pedidos.map((p) => p.$1).toSet(),
          {TipoSolicitud.comercio});
      expect(env.solicitudes.pedidos.map((p) => p.$2.page), [0, 1, 2]);
      await bloc.close();
    });

    test('GetSolicitudesPendientesUseCase pasa el tipo y la página', () async {
      final env = TestEnv();
      env.solicitudes.pendientesPorTipo[TipoSolicitud.repartidor]!
          .add(solicitudRepartidor());

      final page = await env.getPendientes(
          TipoSolicitud.repartidor, const PageRequest());

      expect(page.items.single.nombre, 'Luis Torres');
      expect(page.hasMore, isFalse);
    });
  });
}
