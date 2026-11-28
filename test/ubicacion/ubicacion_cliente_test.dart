import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/radio_reglas.dart';
import 'package:smartcart/features/ubicacion/presentation/formato_distancia.dart';

import '../support/fakes.dart';
import '../support/fakes_ubicacion.dart';

void main() {
  group('RadioReglas', () {
    test('el radio va de 1 a 20 km, con los límites incluidos', () {
      expect(RadioReglas.radioValido(1000), isTrue);
      expect(RadioReglas.radioValido(20000), isTrue);
      expect(RadioReglas.radioValido(999), isFalse);
      expect(RadioReglas.radioValido(20001), isFalse);
    });

    test('todas las opciones de la pantalla son válidas e incluyen la inicial',
        () {
      expect(RadioReglas.opcionesM.every(RadioReglas.radioValido), isTrue);
      expect(RadioReglas.opcionesM, contains(RadioReglas.porDefectoM));
    });
  });

  group('formatos', () {
    test('la distancia en metros o en km con coma decimal', () {
      expect(formatoDistancia(85.4), '85 m');
      expect(formatoDistancia(3336), '3,3 km');
    });

    test('el radio en km enteros', () {
      expect(formatoRadio(5000), '5 km');
      expect(formatoRadio(20000), '20 km');
    });
  });

  group('PreferenciaUbicacion', () {
    test('sin dirección es del GPS; cambiar el radio conserva lo demás', () {
      const gps =
          PreferenciaUbicacion(ubicacion: ubicacionCliente, radioM: 5000);
      final escrita = const PreferenciaUbicacion(
        ubicacion: ubicacionDireccion,
        radioM: 5000,
        direccion: direccionEjemplo,
      ).conRadio(10000);

      expect(gps.desdeGps, isTrue);
      expect(escrita.desdeGps, isFalse);
      expect(escrita.radioM, 10000);
      expect(escrita.direccion, direccionEjemplo);
      expect(escrita.ubicacion, ubicacionDireccion);
    });
  });

  group('casos de uso', () {
    late TestEnv env;

    setUp(() => env = TestEnv()..iniciarSesionComoClienteConComercios());

    test('sin nada guardado devuelve null; después, lo guardado', () async {
      expect(await env.getMiUbicacion(), isNull);

      const preferencia =
          PreferenciaUbicacion(ubicacion: ubicacionCliente, radioM: 2000);
      await env.guardarMiUbicacion(preferencia);

      expect(await env.getMiUbicacion(), preferencia);
    });

    test('un radio fuera de rango no se guarda ni se consulta', () async {
      for (final radio in [500, 25000]) {
        final preferencia =
            PreferenciaUbicacion(ubicacion: ubicacionCliente, radioM: radio);
        await expectLater(
          env.guardarMiUbicacion(preferencia),
          throwsA(isA<AuthFailure>().having(
              (f) => f.message, 'mensaje', contains('entre 1 y 20 km'))),
        );
        await expectLater(
            env.getComerciosEnRadio(preferencia), throwsA(isA<AuthFailure>()));
      }
      expect(env.ubicacion.repositorio.guardadas, isEmpty);
    });

    test('una dirección de más de 200 caracteres no se guarda', () async {
      final preferencia = PreferenciaUbicacion(
        ubicacion: ubicacionDireccion,
        radioM: 5000,
        direccion: 'x' * 201,
      );

      await expectLater(
          env.guardarMiUbicacion(preferencia), throwsA(isA<AuthFailure>()));
      expect(env.ubicacion.repositorio.guardadas, isEmpty);
    });

    test('una cuenta sin el perfil cliente no guarda su ubicación', () async {
      env.iniciarSesionCon({UserRole.colaborador});

      await expectLater(
        env.guardarMiUbicacion(const PreferenciaUbicacion(
            ubicacion: ubicacionCliente, radioM: 5000)),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.ubicacion.repositorio.guardadas, isEmpty);
    });

    test('escenarios 1 y 3: solo entran los comercios dentro del radio, '
        'del más cercano al más lejano', () async {
      final con2 = await env.getComerciosEnRadio(const PreferenciaUbicacion(
          ubicacion: ubicacionCliente, radioM: 2000));
      final con10 = await env.getComerciosEnRadio(const PreferenciaUbicacion(
          ubicacion: ubicacionCliente, radioM: 10000));

      expect(con2.map((c) => c.id), ['c1']);
      expect(con10.map((c) => c.id), ['c1', 'c2', 'c3']);
    });

    test('escenario 2: la dirección escrita se limpia y se convierte en '
        'coordenadas', () async {
      final encontrada =
          await env.buscarDireccion('  Calle 5   # 38-20,  Cali ');

      expect(encontrada.direccion, 'Calle 5 # 38-20, Cali');
      expect(encontrada.ubicacion, ubicacionDireccion);
    });

    test('una dirección muy corta o muy larga no se busca', () async {
      await expectLater(env.buscarDireccion('Cra'),
          throwsA(isA<AuthFailure>().having(
              (f) => f.message, 'mensaje', contains('dirección completa'))));
      await expectLater(
          env.buscarDireccion('x' * 201), throwsA(isA<AuthFailure>()));
      expect(env.ubicacion.geocodificador.buscadas, isEmpty);
    });

    test('si no encuentra la dirección llega el mensaje del geocodificador',
        () async {
      await expectLater(
        env.buscarDireccion('Calle que no existe 123'),
        throwsA(isA<AuthFailure>().having(
            (f) => f.message, 'mensaje', contains('No encontramos'))),
      );
    });
  });
}
