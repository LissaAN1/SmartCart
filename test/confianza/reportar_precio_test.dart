import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/busqueda/presentation/bloc/detalle_producto_bloc.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';

import '../busqueda/busqueda_datos.dart';
import '../support/fakes.dart';

/// Un detalle ya cargado, con la sesión de un cliente.
Future<(TestEnv, DetalleProductoBloc)> _bloc() async {
  final env = entornoBusqueda();
  final bloc = env.detalleBloc(const ConsultaPorClave('cb:7701234567890'))
    ..add(DetalleProductoStarted());
  await bloc.stream.firstWhere((s) => s.status == DetalleProductoStatus.ready);
  return (env, bloc);
}

void main() {
  group('ReportarPrecioIncorrectoUseCase · escenario 3', () {
    test('guarda un reporte pendiente del precio', () async {
      final env = entornoBusqueda();

      final resultado = await env.reportarPrecioIncorrecto('p1');

      expect(resultado, ResultadoReporte.registrado);
      expect(env.reporteIncorrecto.reportes.single.idProducto, 'p1');
    });

    test('el motivo es opcional y se guarda sin espacios sobrantes', () async {
      final env = entornoBusqueda();

      await env.reportarPrecioIncorrecto('p1', motivo: '  En la tienda vale 4.000  ');

      expect(env.reporteIncorrecto.reportes.single.motivo,
          'En la tienda vale 4.000');
    });

    test('un motivo en blanco se guarda como si no hubiera', () async {
      final env = entornoBusqueda();

      await env.reportarPrecioIncorrecto('p1', motivo: '   ');

      expect(env.reporteIncorrecto.reportes.single.motivo, isNull);
    });

    test('un motivo de 300 caracteres pasa y de 301 no', () async {
      final env = entornoBusqueda();

      await env.reportarPrecioIncorrecto('p1', motivo: 'x' * 300);
      expect(env.reporteIncorrecto.reportes, hasLength(1));

      await expectLater(
        env.reportarPrecioIncorrecto('p2', motivo: 'x' * 301),
        throwsA(isA<AuthFailure>().having(
            (e) => e.message, 'mensaje', contains('300 caracteres'))),
      );
      expect(env.reporteIncorrecto.reportes, hasLength(1));
    });

    test('reportar dos veces el mismo precio no crea otro reporte', () async {
      final env = entornoBusqueda();

      await env.reportarPrecioIncorrecto('p1');
      final segundo = await env.reportarPrecioIncorrecto('p1');

      expect(segundo, ResultadoReporte.yaReportado);
      expect(env.reporteIncorrecto.reportes, hasLength(1));
    });

    test('sin producto elegido no se envía nada', () async {
      final env = entornoBusqueda();

      await expectLater(
          env.reportarPrecioIncorrecto('  '), throwsA(isA<AuthFailure>()));
      expect(env.reporteIncorrecto.reportes, isEmpty);
    });

    test('sin sesión pide iniciar sesión', () async {
      final env = TestEnv();

      await expectLater(
        env.reportarPrecioIncorrecto('p1'),
        throwsA(isA<AuthFailure>().having(
            (e) => e.message, 'mensaje', contains('Inicia sesión'))),
      );
      expect(env.reporteIncorrecto.reportes, isEmpty);
    });

    test('solo un cliente puede reportar', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.comercio});

      await expectLater(
          env.reportarPrecioIncorrecto('p1'), throwsA(isA<AuthFailure>()));
      expect(env.reporteIncorrecto.reportes, isEmpty);
    });

    test('un error del repositorio sube tal cual', () async {
      final env = entornoBusqueda();
      env.reporteIncorrecto.error = const AuthFailure('Ese precio ya no está publicado.');

      await expectLater(
        env.reportarPrecioIncorrecto('p1'),
        throwsA(isA<AuthFailure>().having(
            (e) => e.message, 'mensaje', contains('ya no está publicado'))),
      );
    });
  });

  group('DetalleProductoBloc · reportar un precio', () {
    test('al reportar, el precio queda como reportado y avisa', () async {
      final (env, bloc) = await _bloc();

      bloc.add(PrecioIncorrectoReportado('p1', motivo: 'Está más caro'));
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));

      expect(bloc.state.reportando, isEmpty);
      expect(bloc.state.aviso?.texto, contains('Gracias'));
      expect(bloc.state.aviso?.esError, isFalse);
      expect(env.reporteIncorrecto.reportes.single.motivo, 'Está más caro');
      expect(bloc.state.detalle, isNotNull, reason: 'el detalle se conserva');
      await bloc.close();
    });

    test('mientras se envía, el precio figura como en curso', () async {
      final (env, bloc) = await _bloc();
      env.reporteIncorrecto.pausa = Completer<void>();

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.reportando.contains('p1'));
      expect(bloc.state.reportados, isEmpty);

      env.reporteIncorrecto.pausa!.complete();
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));
      expect(bloc.state.reportando, isEmpty);
      await bloc.close();
    });

    test('un segundo toque mientras se envía no manda otro reporte', () async {
      final (env, bloc) = await _bloc();
      env.reporteIncorrecto.pausa = Completer<void>();

      bloc
        ..add(PrecioIncorrectoReportado('p1'))
        ..add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.reportando.contains('p1'));
      env.reporteIncorrecto.pausa!.complete();
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));
      await Future<void>.delayed(Duration.zero);

      expect(env.reporteIncorrecto.reportes, hasLength(1));
      await bloc.close();
    });

    test('un precio ya reportado no se vuelve a enviar', () async {
      final (env, bloc) = await _bloc();

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));
      bloc.add(PrecioIncorrectoReportado('p1'));
      await Future<void>.delayed(Duration.zero);

      expect(env.reporteIncorrecto.reportes, hasLength(1));
      await bloc.close();
    });

    test('si ya había un reporte pendiente, lo dice y lo da por reportado',
        () async {
      final (env, bloc) = await _bloc();
      await env.reportarPrecioIncorrecto('p1'); // de otra sesión o pantalla

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));

      expect(bloc.state.aviso?.texto, contains('Ya reportaste'));
      expect(env.reporteIncorrecto.reportes, hasLength(1));
      await bloc.close();
    });

    test('si falla, avisa el motivo y se puede intentar de nuevo', () async {
      final (env, bloc) = await _bloc();
      env.reporteIncorrecto.error = const AuthFailure('Ese precio ya no está publicado.');

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.aviso != null);

      expect(bloc.state.aviso?.texto, 'Ese precio ya no está publicado.');
      expect(bloc.state.aviso?.esError, isTrue);
      expect(bloc.state.reportando, isEmpty);
      expect(bloc.state.reportados, isEmpty);

      env.reporteIncorrecto.error = null;
      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));
      expect(env.reporteIncorrecto.reportes, hasLength(1));
      await bloc.close();
    });

    test('un error inesperado da un mensaje genérico', () async {
      final (env, bloc) = await _bloc();
      env.reporteIncorrecto.error = StateError('algo raro');

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.aviso != null);

      expect(bloc.state.aviso?.texto, contains('No pudimos enviar'));
      expect(bloc.state.aviso?.esError, isTrue);
      await bloc.close();
    });

    test('cada aviso lleva un id distinto, aunque el texto sea el mismo',
        () async {
      final (env, bloc) = await _bloc();
      env.reporteIncorrecto.error = const AuthFailure('Falló');

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.aviso != null);
      final primero = bloc.state.aviso!.id;
      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => (s.aviso?.id ?? 0) > primero);

      expect(bloc.state.aviso!.id, isNot(primero));
      expect(bloc.state.aviso!.texto, 'Falló');
      await bloc.close();
    });

    test('dos precios distintos se reportan a la vez sin pisarse', () async {
      final (env, bloc) = await _bloc();
      env.reporteIncorrecto.pausa = Completer<void>();

      bloc
        ..add(PrecioIncorrectoReportado('p1'))
        ..add(PrecioIncorrectoReportado('p2'));
      await bloc.stream.firstWhere((s) => s.reportando.length == 2);
      env.reporteIncorrecto.pausa!.complete();
      await bloc.stream.firstWhere((s) => s.reportados.length == 2);

      expect(bloc.state.reportando, isEmpty);
      expect(bloc.state.reportados, {'p1', 'p2'});
      expect(env.reporteIncorrecto.reportes, hasLength(2));
      await bloc.close();
    });

    test('reportar no cambia lo que muestra el detalle', () async {
      final (_, bloc) = await _bloc();
      final antes = bloc.state.detalle;

      bloc.add(PrecioIncorrectoReportado('p1'));
      await bloc.stream.firstWhere((s) => s.reportados.contains('p1'));

      expect(bloc.state.detalle, same(antes));
      expect(bloc.state.status, DetalleProductoStatus.ready);
      await bloc.close();
    });
  });

  test('sin sesión, reportar avisa y no deja el envío en curso', () async {
    final bloc = TestEnv().detalleBloc(const ConsultaPorClave('x'));
    final estados = <DetalleProductoState>[];
    final suscripcion = bloc.stream.listen(estados.add);

    bloc.add(PrecioIncorrectoReportado('p1'));
    await bloc.stream.firstWhere((s) => s.aviso != null);
    await suscripcion.cancel();

    expect(estados.first.reportando, {'p1'});
    expect(estados.last.aviso?.esError, isTrue);
    expect(estados.last.reportando, isEmpty);
    await bloc.close();
  });
}
