import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';

import '../support/fakes.dart';

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
    env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  });

  group('ActualizarPrecioUseCase · escenario 1', () {
    test('guarda el precio con la fecha, la hora y la fuente "Comercio"',
        () async {
      final precio =
          await env.actualizarPrecio('p1', const PrecioDatos(precio: 2500));

      expect(precio.precio, 2500);
      expect(precio.fuente, FuentePrecio.comercio);
      expect(precio.actualizadoEn, env.precios.fecha);
    });

    test('conserva el historial de precios', () async {
      await env.actualizarPrecio('p1', const PrecioDatos(precio: 2500));
      await env.actualizarPrecio('p1', const PrecioDatos(precio: 2800));

      final ficha = await env.getFichaPrecio('p1');
      expect([for (final r in ficha.historial) r.precio], [2800, 2500]);
    });

    test('rechaza un precio en cero sin llamar a la base', () async {
      await expectLater(
        env.actualizarPrecio('p1', const PrecioDatos(precio: 0)),
        _falla('mayor a cero'),
      );
      expect(env.precios.guardados, isEmpty);
    });

    test('un comercio pendiente no puede cambiar precios', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(
        env.actualizarPrecio('p1', const PrecioDatos(precio: 2500)),
        _falla('pendiente de aprobación'),
      );
      expect(env.precios.guardados, isEmpty);
    });

    test('el error de la base llega con su mensaje', () async {
      env.precios.guardarError = const AuthFailure('Sin conexión');

      await expectLater(
        env.actualizarPrecio('p1', const PrecioDatos(precio: 2500)),
        _falla('Sin conexión'),
      );
    });
  });

  group('CambiarDisponibilidadProductoUseCase · escenario 2', () {
    test('marca agotado conservando el precio', () async {
      env.precios.precargar('p1', 2500);

      final precio = await env.cambiarDisponibilidadProducto('p1', false);

      expect(precio.disponible, isFalse);
      expect(precio.precio, 2500);
      expect(env.precios.historiales['p1']!.single.disponible, isFalse);
    });

    test('sin precio pide registrarlo primero', () async {
      await expectLater(
        env.cambiarDisponibilidadProducto('p1', false),
        _falla('Registra el precio'),
      );
    });

    test('si no cambia nada no escribe', () async {
      env.precios.precargar('p1', 2500);

      await env.cambiarDisponibilidadProducto('p1', true);

      expect(env.precios.guardados, isEmpty);
    });
  });

  group('GuardarPromocionUseCase', () {
    final datos = PromocionDatos(
      precioPromocional: 2000,
      inicio: DateTime(2026, 11, 15, 18),
      fin: DateTime(2026, 11, 30, 9),
    );

    test('guarda la promoción solo con las fechas, sin hora', () async {
      env.precios.precargar('p1', 2500);

      final promo = await env.guardarPromocion('p1', datos);

      expect(promo.precioPromocional, 2000);
      expect(promo.inicio, DateTime(2026, 11, 15));
      expect(promo.fin, DateTime(2026, 11, 30));
    });

    test('el precio promocional debe ser menor que el normal', () async {
      env.precios.precargar('p1', 1800);

      await expectLater(
        env.guardarPromocion('p1', datos),
        _falla('menos que el precio normal'),
      );
      expect(env.precios.promociones, isEmpty);
    });

    test('sin precio normal no se puede crear', () async {
      await expectLater(
        env.guardarPromocion('p1', datos),
        _falla('precio normal'),
      );
    });

    test('rechaza fechas invertidas', () async {
      env.precios.precargar('p1', 2500);

      await expectLater(
        env.guardarPromocion(
          'p1',
          PromocionDatos(
            precioPromocional: 2000,
            inicio: DateTime(2026, 11, 20),
            fin: DateTime(2026, 11, 18),
          ),
        ),
        _falla('posterior'),
      );
    });
  });

  group('QuitarPromocionUseCase', () {
    test('elimina la promoción y vuelve el precio normal', () async {
      env.precios.precargar('p1', 2500);
      await env.guardarPromocion(
        'p1',
        PromocionDatos(
          precioPromocional: 2000,
          inicio: DateTime(2026, 11, 15),
          fin: DateTime(2026, 11, 30),
        ),
      );

      await env.quitarPromocion('p1');

      final ficha = await env.getFichaPrecio('p1');
      expect(ficha.promocion, isNull);
      expect(ficha.precioMostrado(env.ahora), 2500);
    });
  });

  group('GetFichaPrecioUseCase', () {
    test('un producto sin precio devuelve la ficha vacía', () async {
      final ficha = await env.getFichaPrecio('p1');

      expect(ficha.precio, isNull);
      expect(ficha.promocion, isNull);
      expect(ficha.historial, isEmpty);
    });

    test('un comercio rechazado no puede verla', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.rechazado);

      await expectLater(env.getFichaPrecio('p1'), _falla('rechazado'));
    });
  });
}
