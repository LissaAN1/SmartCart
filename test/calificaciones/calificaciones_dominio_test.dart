import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/calificaciones/domain/calificacion_reglas.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';

import '../support/fakes.dart';
import '../support/fakes_ordenes.dart';

void main() {
  group('CalificacionReglas · rango de estrellas', () {
    test('de 1 a 5 es válido', () {
      for (final e in [1, 2, 3, 4, 5]) {
        expect(CalificacionReglas.estrellasValidas(e), isTrue, reason: '$e');
        expect(CalificacionReglas.validar(e, null), isNull);
      }
    });

    test('fuera de 1 a 5 se rechaza con el mensaje', () {
      for (final e in [-1, 0, 6, 10]) {
        expect(CalificacionReglas.estrellasValidas(e), isFalse, reason: '$e');
        expect(CalificacionReglas.validar(e, null),
            'La calificación va de 1 a 5 estrellas.');
      }
    });

    test('el comentario es opcional y llega hasta 500 caracteres', () {
      expect(CalificacionReglas.validar(4, null), isNull);
      expect(CalificacionReglas.validar(4, ''), isNull);
      expect(CalificacionReglas.validar(4, 'a' * 500), isNull);
      expect(CalificacionReglas.validar(4, 'a' * 501),
          CalificacionReglas.mensajeComentarioLargo);
    });

    test('limpiar el comentario quita espacios y vacío es nulo', () {
      expect(CalificacionReglas.limpiarComentario('  Muy bueno  '), 'Muy bueno');
      expect(CalificacionReglas.limpiarComentario('   '), isNull);
      expect(CalificacionReglas.limpiarComentario(null), isNull);
    });
  });

  group('CalificacionReglas.promedio', () {
    test('es la media de las estrellas', () {
      expect(CalificacionReglas.promedio([5, 4, 3]), 4.0);
      expect(CalificacionReglas.promedio([5, 4]), 4.5);
      expect(CalificacionReglas.promedio([1, 1, 2]), closeTo(1.3333, 0.001));
      expect(CalificacionReglas.promedio([5]), 5.0);
    });

    test('sin calificaciones no hay promedio', () {
      expect(CalificacionReglas.promedio(const []), isNull);
    });
  });

  group('ResumenCalificaciones', () {
    test('sin calificaciones dice "Sin calificaciones"', () {
      expect(ResumenCalificaciones.sinCalificaciones.etiqueta,
          'Sin calificaciones');
      expect(const ResumenCalificaciones(promedio: null, total: 0).tiene,
          isFalse);
    });

    test('con calificaciones muestra promedio y total', () {
      const resumen = ResumenCalificaciones(promedio: 4.5, total: 12);
      expect(resumen.tiene, isTrue);
      expect(resumen.etiqueta, '4.5 (12)');
      expect(const ResumenCalificaciones(promedio: 4, total: 1).etiqueta,
          '4.0 (1)');
    });
  });

  group('CalificarOrdenUseCase', () {
    late TestEnv env;

    setUp(() {
      env = TestEnv()..iniciarSesionComoClienteConCompras();
    });

    test('califica la orden y devuelve el nuevo promedio', () async {
      final resumen = await env.calificarOrden(
        idOrden: 'o1',
        tipo: TipoCalificacion.comercio,
        estrellas: 4,
        comentario: '  Buen servicio  ',
      );

      expect(resumen.promedio, 4.0);
      expect(resumen.total, 1);
      final enviada = env.ordenes.calificaciones.enviadas.single;
      expect(enviada.idOrden, 'o1');
      expect(enviada.tipo, TipoCalificacion.comercio);
      expect(enviada.estrellas, 4);
      expect(enviada.comentario, 'Buen servicio');
    });

    test('el comentario vacío se envía como nulo', () async {
      await env.calificarOrden(
        idOrden: 'o1',
        tipo: TipoCalificacion.comercio,
        estrellas: 5,
        comentario: '   ',
      );
      expect(env.ordenes.calificaciones.enviadas.single.comentario, isNull);
    });

    test('estrellas fuera de rango no llegan a la base', () async {
      for (final e in [0, 6]) {
        await expectLater(
          env.calificarOrden(
              idOrden: 'o1', tipo: TipoCalificacion.comercio, estrellas: e),
          throwsA(isA<AuthFailure>().having(
              (f) => f.message, 'message', CalificacionReglas.mensajeRango)),
        );
      }
      expect(env.ordenes.calificaciones.calls, 0);
    });

    test('una orden se califica una sola vez por tipo', () async {
      await env.calificarOrden(
          idOrden: 'o1', tipo: TipoCalificacion.comercio, estrellas: 5);

      await expectLater(
        env.calificarOrden(
            idOrden: 'o1', tipo: TipoCalificacion.comercio, estrellas: 1),
        throwsA(isA<AuthFailure>()
            .having((f) => f.message, 'message', 'Ya calificaste esta orden.')),
      );
      // Al repartidor de la misma orden sí se le puede calificar.
      await env.calificarOrden(
          idOrden: 'o1', tipo: TipoCalificacion.repartidor, estrellas: 3);
      expect(env.ordenes.calificaciones.enviadas.length, 2);
    });

    test('el promedio se calcula con todas las calificaciones recibidas',
        () async {
      await env.calificarOrden(
          idOrden: 'o1', tipo: TipoCalificacion.comercio, estrellas: 5);
      final resumen = await env.calificarOrden(
          idOrden: 'o2', tipo: TipoCalificacion.comercio, estrellas: 4);

      expect(resumen.promedio, 4.5);
      expect(resumen.total, 2);
    });

    test('solo el cliente califica', () async {
      env.iniciarSesionCon({UserRole.comercio});
      await expectLater(
        env.calificarOrden(
            idOrden: 'o1', tipo: TipoCalificacion.comercio, estrellas: 5),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.ordenes.calificaciones.calls, 0);
    });
  });
}
