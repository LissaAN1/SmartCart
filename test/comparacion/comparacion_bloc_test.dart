import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/comparacion_bloc.dart';
import 'package:smartcart/features/comparacion/presentation/bloc/precios_carrito_bloc.dart';
import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';

import '../support/fakes.dart';
import '../support/fakes_comparacion.dart';
import '../support/fakes_ubicacion.dart';

void main() {
  late TestEnv env;
  late ComparacionBloc bloc;

  Future<ComparacionState> hasta(bool Function(ComparacionState s) c) =>
      bloc.stream.firstWhere(c);

  void conUbicacion() => env.ubicacion.repositorio.guardada =
      const PreferenciaUbicacion(ubicacion: ubicacionCliente, radioM: 5000);

  setUp(() {
    env = TestEnv()..iniciarSesionComoClienteConComercios();
    env.comparacion.lineas = carritoEjemplo();
    bloc = env.comparacionBloc();
  });

  tearDown(() => bloc.close());

  test('al iniciar lee las ofertas y la ubicación y arma las tres '
      'alternativas, con el criterio elegido primero', () async {
    conUbicacion();

    bloc.add(ComparacionIniciada());
    final lista = await hasta((s) => s.status == ComparacionStatus.lista);

    expect(lista.alternativas.map((a) => a.criterio), [
      CriterioCompra.ahorro,
      CriterioCompra.calidadPrecio,
      CriterioCompra.comodidad,
    ]);
    expect(lista.alternativas.first.ahorro, 2200);
    expect(lista.alternativas.first.distanciaTotalM, isNotNull);
  });

  test('cambiar el criterio lo pone primero sin volver a la red', () async {
    bloc.add(ComparacionIniciada());
    await hasta((s) => s.status == ComparacionStatus.lista);

    bloc.add(ComparacionCriterioElegido(CriterioCompra.comodidad));
    final s = await hasta((s) => s.criterio == CriterioCompra.comodidad);

    expect(s.alternativas.first.criterio, CriterioCompra.comodidad);
    expect(env.comparacion.llamadas, 1);
  });

  test('escenario 4: la distancia máxima recalcula sin el comercio lejano',
      () async {
    conUbicacion();
    bloc.add(ComparacionIniciada());
    await hasta((s) => s.status == ComparacionStatus.lista);

    bloc.add(ComparacionDistanciaElegida(5000));
    final s = await hasta((s) => s.distanciaMaxM == 5000);

    final ahorro = s.resultado!.alternativas[CriterioCompra.ahorro]!;
    expect(ahorro.comercios.map((c) => c.idComercio), isNot(contains('C')));
    expect(env.comparacion.llamadas, 1);

    bloc.add(ComparacionDistanciaElegida(null));
    final sinLimite = await hasta((s) => s.distanciaMaxM == null);
    expect(
        sinLimite.resultado!.alternativas[CriterioCompra.ahorro]!.comercios
            .map((c) => c.idComercio),
        contains('C'));
  });

  test('sin ubicación compara igual (distancia no disponible) y no deja fijar '
      'una distancia máxima', () async {
    bloc.add(ComparacionIniciada());
    final lista = await hasta((s) => s.status == ComparacionStatus.lista);
    expect(lista.ubicacion, isNull);
    expect(lista.alternativas.first.distanciaTotalM, isNull);

    bloc.add(ComparacionDistanciaElegida(5000));
    final s = await hasta((s) => s.errorMessage != null);

    expect(s.errorMessage, contains('Configura tu ubicación'));
    expect(s.distanciaMaxM, isNull);
    expect(s.alternativas, hasLength(3));
  });

  test('al volver del mapa usa la ubicación recién guardada', () async {
    bloc.add(ComparacionIniciada());
    await hasta((s) => s.status == ComparacionStatus.lista);

    conUbicacion();
    bloc.add(ComparacionUbicacionRecargada());
    final s = await hasta((s) => s.ubicacion != null);

    expect(s.alternativas.first.distanciaTotalM, isNotNull);
  });

  test('si la ubicación no se puede leer, la comparación sigue', () async {
    env.ubicacion.repositorio.errorAlLeer = const AuthFailure('Sin conexión.');

    bloc.add(ComparacionIniciada());
    final lista = await hasta((s) => s.status == ComparacionStatus.lista);

    expect(lista.ubicacion, isNull);
    expect(lista.alternativas, hasLength(3));
  });

  test('escenario 6: con el carrito vacío no hay alternativas', () async {
    env.comparacion.lineas = [];

    bloc.add(ComparacionIniciada());
    final vacia = await hasta((s) => s.status == ComparacionStatus.vacia);

    expect(vacia.alternativas, isEmpty);
  });

  test('si la carga falla deja el mensaje y se puede reintentar', () async {
    env.comparacion.error = const AuthFailure('Sin conexión.');

    bloc.add(ComparacionIniciada());
    final fallo =
        await hasta((s) => s.status == ComparacionStatus.falloCarga);
    expect(fallo.errorMessage, 'Sin conexión.');

    env.comparacion.error = null;
    bloc.add(ComparacionIniciada());
    await hasta((s) => s.status == ComparacionStatus.lista);
  });

  group('PreciosCarritoBloc', () {
    test('trae el precio vigente del producto de cada línea', () async {
      final precios = env.preciosCarritoBloc();
      addTearDown(precios.close);

      precios.add(PreciosCarritoSolicitados());
      final s = await precios.stream
          .firstWhere((s) => s.status == PreciosCarritoStatus.listos);

      expect(s.precios['arroz-a']!.precio, 5000);
      expect(s.precios['cafe-b']!.precio, 12000);
    });

    test('si falla conserva los precios anteriores y deja el mensaje',
        () async {
      final precios = env.preciosCarritoBloc();
      addTearDown(precios.close);
      precios.add(PreciosCarritoSolicitados());
      await precios.stream
          .firstWhere((s) => s.status == PreciosCarritoStatus.listos);

      env.comparacion.error = const AuthFailure('Sin conexión.');
      precios.add(PreciosCarritoSolicitados());
      final s = await precios.stream
          .firstWhere((s) => s.status == PreciosCarritoStatus.fallidos);

      expect(s.errorMessage, 'Sin conexión.');
      expect(s.precios, hasLength(4));
    });
  });
}
