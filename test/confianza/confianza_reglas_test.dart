import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/confianza/domain/confianza_reglas.dart';
import 'package:smartcart/features/confianza/domain/entities/confianza_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';

/// "Hoy" de las pruebas: 15 de noviembre de 2026, a mediodía.
final _ahora = DateTime(2026, 11, 15, 12);

/// Un precio actualizado hace [dias] días de calendario, a la misma hora.
DateTime _hace(int dias) => DateTime(2026, 11, 15 - dias, 12);

ConfianzaPrecio _calcular(FuentePrecio fuente, DateTime fecha) =>
    ConfianzaReglas.calcular(
      fuente: fuente,
      actualizadoEn: fecha,
      ahora: _ahora,
    );

void main() {
  group('Escenario 1: precio reciente de un comercio', () {
    test('actualizado hoy: confianza alta, no desactualizado', () {
      final c = _calcular(FuentePrecio.comercio, DateTime(2026, 11, 15, 9, 30));

      expect(c.nivel, NivelConfianza.alto);
      expect(c.desactualizado, isFalse);
      expect(c.dias, 0);
      expect(c.antiguedad, 'hoy');
    });

    test('hasta 3 días sigue siendo alta', () {
      expect(_calcular(FuentePrecio.comercio, _hace(1)).nivel,
          NivelConfianza.alto);
      expect(_calcular(FuentePrecio.comercio, _hace(3)).nivel,
          NivelConfianza.alto);
    });
  });

  group('Escenario 2: precio desactualizado', () {
    test('más de 7 días: se marca desactualizado y baja a confianza baja', () {
      final c = _calcular(FuentePrecio.comercio, _hace(8));

      expect(c.desactualizado, isTrue);
      expect(c.nivel, NivelConfianza.bajo);
      expect(c.nivel.index, lessThan(NivelConfianza.alto.index));
    });

    test('exactamente 7 días todavía no está desactualizado', () {
      final c = _calcular(FuentePrecio.comercio, _hace(7));

      expect(c.desactualizado, isFalse);
      expect(c.nivel, NivelConfianza.medio);
    });

    test('el límite es el que fijamos: 7 días', () {
      expect(ConfianzaReglas.diasLimite, 7);
      expect(ConfianzaReglas.diasReciente, 3);
    });

    test('un precio de hace meses sigue en baja y desactualizado', () {
      final c = _calcular(FuentePrecio.comercio, _hace(200));

      expect(c.nivel, NivelConfianza.bajo);
      expect(c.desactualizado, isTrue);
      expect(c.antiguedad, 'hace 200 días');
    });
  });

  group('Del comercio: la confianza baja con los días', () {
    final esperado = <int, NivelConfianza>{
      0: NivelConfianza.alto,
      3: NivelConfianza.alto,
      4: NivelConfianza.medio,
      7: NivelConfianza.medio,
      8: NivelConfianza.bajo,
    };
    esperado.forEach((dias, nivel) {
      test('$dias días → $nivel', () {
        expect(_calcular(FuentePrecio.comercio, _hace(dias)).nivel, nivel);
      });
    });
  });

  group('De la comunidad: nunca llega a alta', () {
    final esperado = <int, NivelConfianza>{
      0: NivelConfianza.medio,
      3: NivelConfianza.medio,
      4: NivelConfianza.bajo,
      7: NivelConfianza.bajo,
      8: NivelConfianza.bajo,
    };
    esperado.forEach((dias, nivel) {
      test('$dias días → $nivel', () {
        expect(_calcular(FuentePrecio.colaborador, _hace(dias)).nivel, nivel);
      });
    });

    test('también se marca desactualizado pasados los 7 días', () {
      expect(_calcular(FuentePrecio.colaborador, _hace(7)).desactualizado,
          isFalse);
      expect(_calcular(FuentePrecio.colaborador, _hace(8)).desactualizado,
          isTrue);
    });

    test('a igual antigüedad, la comunidad no supera al comercio', () {
      for (var dias = 0; dias <= 12; dias++) {
        final comercio = _calcular(FuentePrecio.comercio, _hace(dias));
        final comunidad = _calcular(FuentePrecio.colaborador, _hace(dias));
        expect(comunidad.nivel.index, lessThanOrEqualTo(comercio.nivel.index),
            reason: '$dias días');
      }
    });
  });

  group('Días de antigüedad', () {
    test('cuenta días de calendario, no períodos de 24 horas', () {
      // Ayer a las 23:59 y hoy a las 00:01: pasaron 2 minutos, pero es "ayer".
      final ahora = DateTime(2026, 11, 15, 0, 1);

      expect(
        ConfianzaReglas.diasDeAntiguedad(DateTime(2026, 11, 14, 23, 59), ahora),
        1,
      );
    });

    test('hace 25 horas pueden ser 1 o 2 días según la fecha', () {
      expect(
        ConfianzaReglas.diasDeAntiguedad(
            DateTime(2026, 11, 14, 11), DateTime(2026, 11, 15, 12)),
        1,
      );
    });

    test('una fecha en el futuro cuenta como hoy', () {
      final c = ConfianzaReglas.calcular(
        fuente: FuentePrecio.comercio,
        actualizadoEn: DateTime(2026, 11, 20),
        ahora: _ahora,
      );

      expect(c.dias, 0);
      expect(c.nivel, NivelConfianza.alto);
    });

    test('cruza el cambio de mes y de año', () {
      expect(
        ConfianzaReglas.diasDeAntiguedad(
            DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
        3,
      );
    });

    test('antigüedad escrita: hoy, ayer y hace N días', () {
      expect(_calcular(FuentePrecio.comercio, _hace(0)).antiguedad, 'hoy');
      expect(_calcular(FuentePrecio.comercio, _hace(1)).antiguedad, 'ayer');
      expect(
          _calcular(FuentePrecio.comercio, _hace(5)).antiguedad, 'hace 5 días');
    });
  });

  group('Fuente y niveles', () {
    test('la comunidad se muestra con ese nombre; el código sigue igual', () {
      expect(FuentePrecio.colaborador.etiqueta, 'Comunidad');
      expect(FuentePrecio.colaborador.codigo, 'colaborador');
      expect(FuentePrecio.comercio.etiqueta, 'Comercio');
    });

    test('los niveles van de menor a mayor', () {
      expect(NivelConfianza.values,
          [NivelConfianza.bajo, NivelConfianza.medio, NivelConfianza.alto]);
      expect(NivelConfianza.alto.etiqueta, 'Alta');
    });

    test('dos resultados iguales son iguales', () {
      const a = ConfianzaPrecio(
          nivel: NivelConfianza.alto, desactualizado: false, dias: 0);
      const b = ConfianzaPrecio(
          nivel: NivelConfianza.alto, desactualizado: false, dias: 0);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
