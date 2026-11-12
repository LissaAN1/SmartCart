import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/validators/comercio_validators.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';

import '../support/fakes.dart';

ComercioDatos _con({
  String nombre = 'Minimercado La Esquina',
  String telefono = '+57 300 000 0000',
  String direccion = 'Calle 10 # 5-20',
  String ciudad = 'Cali, San Fernando',
  String apertura = '07:00',
  String cierre = '20:00',
}) =>
    ComercioDatos(
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
      ciudad: ciudad,
      horaApertura: apertura,
      horaCierre: cierre,
      servicio: ServicioComercio.recogida,
    );

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
  });

  group('ComercioValidators', () {
    test('nombre, dirección y ciudad son obligatorios', () {
      expect(ComercioValidators.nombre(''), isNotNull);
      expect(ComercioValidators.nombre('ab'), isNotNull);
      expect(ComercioValidators.nombre('La Esquina'), isNull);
      expect(ComercioValidators.direccion('  '), isNotNull);
      expect(ComercioValidators.ciudad(null), isNotNull);
    });

    test('el teléfono es obligatorio y debe parecer un número', () {
      expect(ComercioValidators.telefono(''), isNotNull);
      expect(ComercioValidators.telefono('abc'), isNotNull);
      expect(ComercioValidators.telefono('+57 300 000 0000'), isNull);
    });

    test('las horas usan el formato HH:mm', () {
      expect(ComercioValidators.hora(''), isNotNull);
      expect(ComercioValidators.hora('25:00'), isNotNull);
      expect(ComercioValidators.hora('7:00'), isNotNull);
      expect(ComercioValidators.hora('07:00'), isNull);
    });

    test('el cierre debe ser después de la apertura', () {
      expect(ComercioValidators.cierre('06:00', '07:00'), isNotNull);
      expect(ComercioValidators.cierre('07:00', '07:00'), isNotNull);
      expect(ComercioValidators.cierre('20:00', '07:00'), isNull);
    });

    test('hay que elegir el tipo de servicio', () {
      expect(ComercioValidators.servicio(null), isNotNull);
      expect(ComercioValidators.servicio(ServicioComercio.entrega), isNull);
    });
  });

  group('RegistrarComercioUseCase', () {
    test('guarda el comercio con estado pendiente', () async {
      final comercio = await env.registrarComercio(comercioDatosValidos);

      expect(comercio.estado, ApprovalStatus.pendiente);
      expect(env.comercios.registerCalls, 1);
      expect(env.comercios.stored?.nombre, 'Minimercado La Esquina');
    });

    test('con un campo obligatorio vacío no guarda nada', () async {
      await expectLater(
        env.registrarComercio(_con(direccion: '')),
        throwsA(isA<AuthFailure>()
            .having((e) => e.message, 'message', contains('dirección'))),
      );
      expect(env.comercios.registerCalls, 0);
    });

    test('con el cierre antes de la apertura no guarda nada', () async {
      await expectLater(
        env.registrarComercio(_con(apertura: '20:00', cierre: '07:00')),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.comercios.registerCalls, 0);
    });

    test('exige una sesión iniciada', () async {
      env.auth.current = null;

      await expectLater(
        env.registrarComercio(comercioDatosValidos),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.comercios.registerCalls, 0);
    });

    test('si ya tiene un comercio devuelve ese y no crea otro', () async {
      env.comercios.stored = comercioConEstado(ApprovalStatus.aprobado);

      final comercio = await env.registrarComercio(comercioDatosValidos);

      expect(comercio.estado, ApprovalStatus.aprobado);
      expect(env.comercios.registerCalls, 0);
    });
  });

  group('ComercioBloc', () {
    Matcher status(ComercioStatus s) =>
        isA<ComercioState>().having((x) => x.status, 'status', s);

    test('leer sin comercio registrado deja ready con comercio nulo', () async {
      final bloc = env.comercioBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          status(ComercioStatus.loading),
          isA<ComercioState>()
              .having((s) => s.status, 'status', ComercioStatus.ready)
              .having((s) => s.comercio, 'comercio', isNull),
        ]),
      );
      bloc.add(ComercioStarted());
      await expectation;
    });

    test('registrar emite saving y luego el comercio pendiente', () async {
      final bloc = env.comercioBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          status(ComercioStatus.saving),
          isA<ComercioState>()
              .having((s) => s.status, 'status', ComercioStatus.ready)
              .having((s) => s.comercio?.estado, 'estado',
                  ApprovalStatus.pendiente),
        ]),
      );
      bloc.add(ComercioSubmitted(comercioDatosValidos));
      await expectation;
    });

    test('un dato inválido emite saveFailed con el mensaje', () async {
      final bloc = env.comercioBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          status(ComercioStatus.saving),
          isA<ComercioState>()
              .having((s) => s.status, 'status', ComercioStatus.saveFailed)
              .having((s) => s.errorMessage, 'error', contains('nombre')),
        ]),
      );
      bloc.add(ComercioSubmitted(_con(nombre: '')));
      await expectation;
      expect(env.comercios.registerCalls, 0);
    });

    test('si falla la lectura emite loadFailed', () async {
      env.comercios.getError = const AuthFailure('Sin conexión.');
      final bloc = env.comercioBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          status(ComercioStatus.loading),
          status(ComercioStatus.loadFailed),
        ]),
      );
      bloc.add(ComercioStarted());
      await expectation;
    });
  });
}
