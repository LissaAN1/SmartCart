import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/radio_reglas.dart';
import 'package:smartcart/features/ubicacion/presentation/bloc/mapa_comercios_bloc.dart';

import '../support/fakes.dart';
import '../support/fakes_ubicacion.dart';

Future<MapaComerciosState> _hasta(
  MapaComerciosBloc bloc,
  bool Function(MapaComerciosState s) condicion,
) =>
    bloc.stream.firstWhere(condicion);

void main() {
  late TestEnv env;
  late MapaComerciosBloc bloc;

  setUp(() {
    env = TestEnv()..iniciarSesionComoClienteConComercios();
    bloc = env.mapaBloc();
  });

  tearDown(() => bloc.close());

  test('escenario 1: la primera vez usa el GPS, guarda la ubicación con el '
      'radio inicial y muestra los comercios de ese radio', () async {
    bloc.add(MapaIniciado());
    final listo = await _hasta(bloc, (s) => s.status == MapaStatus.listo);

    expect(env.servicioUbicacion.llamadas, 1);
    expect(listo.preferencia,
        const PreferenciaUbicacion(
            ubicacion: ubicacionCliente, radioM: RadioReglas.porDefectoM));
    expect(env.ubicacion.repositorio.guardada, listo.preferencia);
    // 5 km: entran el de 0,6 km y el de 3,3 km; no el de 7,8 km.
    expect(listo.comercios.map((c) => c.id), ['c1', 'c2']);
  });

  test('con una ubicación guardada la recupera y no pide el GPS', () async {
    const guardada = PreferenciaUbicacion(
      ubicacion: ubicacionDireccion,
      radioM: 2000,
      direccion: direccionEjemplo,
    );
    env.ubicacion.repositorio.guardada = guardada;

    bloc.add(MapaIniciado());
    final listo = await _hasta(bloc, (s) => s.status == MapaStatus.listo);

    expect(env.servicioUbicacion.llamadas, 0);
    expect(listo.preferencia, guardada);
    expect(listo.comercios.map((c) => c.id), ['c1']);
    expect(env.ubicacion.repositorio.guardadas, isEmpty);
  });

  test('escenario 2: sin permiso pide la dirección y, al escribirla, la '
      'guarda y muestra los comercios', () async {
    env.servicioUbicacion.error = const AuthFailure(
        'Necesitamos el permiso de ubicación para comprobar dónde estás.');

    bloc.add(MapaIniciado());
    final sin =
        await _hasta(bloc, (s) => s.status == MapaStatus.sinUbicacion);
    expect(sin.errorMessage, contains('permiso de ubicación'));
    expect(env.ubicacion.repositorio.guardadas, isEmpty);

    bloc.add(MapaDireccionBuscada(direccionEjemplo));
    final listo = await _hasta(bloc, (s) => s.status == MapaStatus.listo);

    expect(listo.preferencia!.direccion, direccionEjemplo);
    expect(listo.preferencia!.ubicacion, ubicacionDireccion);
    expect(listo.preferencia!.radioM, RadioReglas.porDefectoM);
    expect(env.ubicacion.repositorio.guardada, listo.preferencia);
    expect(listo.aviso?.esError, isFalse);
  });

  test('escenario 3: al ampliar el radio se guarda y entran más comercios',
      () async {
    bloc.add(MapaIniciado());
    await _hasta(bloc, (s) => s.status == MapaStatus.listo);

    bloc.add(MapaRadioCambiado(10000));
    final ampliado = await _hasta(
        bloc, (s) => !s.ocupado && s.preferencia?.radioM == 10000);

    expect(ampliado.comercios.map((c) => c.id), ['c1', 'c2', 'c3']);
    expect(env.ubicacion.repositorio.guardada!.radioM, 10000);
  });

  test('una dirección que no se encuentra avisa y deja todo como estaba',
      () async {
    env.servicioUbicacion.error = const AuthFailure('Sin permiso.');
    bloc.add(MapaIniciado());
    await _hasta(bloc, (s) => s.status == MapaStatus.sinUbicacion);

    bloc.add(MapaDireccionBuscada('Calle que no existe 123'));
    final aviso = await _hasta(bloc, (s) => s.aviso != null);

    expect(aviso.aviso!.esError, isTrue);
    expect(aviso.aviso!.texto, contains('No encontramos'));
    expect(aviso.status, MapaStatus.sinUbicacion);
    expect(aviso.ocupado, isFalse);
    expect(aviso.errorMessage, 'Sin permiso.');
  });

  test('si guardar falla, conserva la ubicación anterior y avisa', () async {
    bloc.add(MapaIniciado());
    final listo = await _hasta(bloc, (s) => s.status == MapaStatus.listo);
    env.ubicacion.repositorio.errorAlGuardar =
        const AuthFailure('Sin conexión.');

    bloc.add(MapaRadioCambiado(20000));
    final aviso = await _hasta(bloc, (s) => s.aviso != null);

    expect(aviso.aviso!.texto, 'Sin conexión.');
    expect(aviso.preferencia, listo.preferencia);
    expect(aviso.comercios.map((c) => c.id), ['c1', 'c2']);
  });

  test('si la carga falla se puede reintentar', () async {
    env.ubicacion.repositorio.errorAlLeer = const AuthFailure('Sin conexión.');

    bloc.add(MapaIniciado());
    final fallo = await _hasta(bloc, (s) => s.status == MapaStatus.falloCarga);
    expect(fallo.errorMessage, 'Sin conexión.');

    env.ubicacion.repositorio.errorAlLeer = null;
    bloc.add(MapaIniciado());
    await _hasta(bloc, (s) => s.status == MapaStatus.listo);
  });

  test('"Usar mi ubicación" reemplaza la dirección por el GPS y conserva el '
      'radio', () async {
    env.ubicacion.repositorio.guardada = const PreferenciaUbicacion(
      ubicacion: ubicacionDireccion,
      radioM: 10000,
      direccion: direccionEjemplo,
    );
    bloc.add(MapaIniciado());
    await _hasta(bloc, (s) => s.status == MapaStatus.listo);

    bloc.add(MapaUbicacionActualSolicitada());
    final gps = await _hasta(bloc, (s) => s.aviso != null);

    expect(gps.preferencia,
        const PreferenciaUbicacion(ubicacion: ubicacionCliente, radioM: 10000));
    expect(gps.preferencia!.desdeGps, isTrue);
  });

  test('mientras guarda no acepta otro cambio', () async {
    bloc.add(MapaIniciado());
    await _hasta(bloc, (s) => s.status == MapaStatus.listo);

    bloc
      ..add(MapaRadioCambiado(10000))
      ..add(MapaRadioCambiado(20000));
    await _hasta(bloc, (s) => !s.ocupado && s.preferencia?.radioM == 10000);
    await Future<void>.delayed(Duration.zero);

    expect(env.ubicacion.repositorio.guardadas.map((p) => p.radioM),
        [RadioReglas.porDefectoM, 10000]);
  });
}
