import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/nivel_colaborador.dart';
import 'package:smartcart/features/puntos/domain/puntos_reglas.dart';

/// HU-16: cálculo de puntos, reputación y nivel.
void main() {
  final ahora = DateTime(2026, 11, 20, 12);

  group('puntos por reporte validado', () {
    test('un producto con precio reciente da los puntos base', () {
      expect(
        PuntosReglas.puntosPorReporte(
          precioActualizadoEn: DateTime(2026, 11, 19),
          ahora: ahora,
        ),
        PuntosReglas.puntosBase,
      );
    });

    test('un producto sin precio (sin datos) da más puntos', () {
      expect(
        PuntosReglas.puntosPorReporte(precioActualizadoEn: null, ahora: ahora),
        PuntosReglas.puntosBase + PuntosReglas.bonusSinDatos,
      );
    });

    test('un precio de más de 7 días (desactualizado) da más puntos', () {
      expect(
        PuntosReglas.puntosPorReporte(
          precioActualizadoEn: DateTime(2026, 11, 12),
          ahora: ahora,
        ),
        PuntosReglas.puntosBase + PuntosReglas.bonusDesactualizado,
      );
    });

    test('exactamente 7 días todavía no cuenta como desactualizado', () {
      expect(
        PuntosReglas.puntosPorReporte(
          precioActualizadoEn: DateTime(2026, 11, 13),
          ahora: ahora,
        ),
        PuntosReglas.puntosBase,
      );
    });

    test('sin datos paga más que desactualizado, y este más que el base', () {
      final sinDatos = PuntosReglas.puntosPorReporte(
          precioActualizadoEn: null, ahora: ahora);
      final viejo = PuntosReglas.puntosPorReporte(
          precioActualizadoEn: DateTime(2026, 10, 1), ahora: ahora);
      final reciente = PuntosReglas.puntosPorReporte(
          precioActualizadoEn: ahora, ahora: ahora);

      expect(sinDatos, greaterThan(viejo));
      expect(viejo, greaterThan(reciente));
    });
  });

  group('reputación', () {
    test('sube con cada reporte validado', () {
      expect(PuntosReglas.reputacionTrasValidado(0), 1);
      expect(PuntosReglas.reputacionTrasValidado(41), 42);
    });

    test('no pasa del máximo', () {
      expect(PuntosReglas.reputacionTrasValidado(100), 100);
      expect(PuntosReglas.reputacionTrasValidado(99.5), 100);
    });

    test('baja con un reporte falso', () {
      expect(PuntosReglas.reputacionTrasFalso(50), 45);
    });

    test('no baja de cero', () {
      expect(PuntosReglas.reputacionTrasFalso(3), 0);
      expect(PuntosReglas.reputacionTrasFalso(0), 0);
    });

    test('un reporte falso pesa más que uno validado', () {
      expect(PuntosReglas.penalizacionPorFalso,
          greaterThan(PuntosReglas.reputacionPorValidado));
    });
  });

  group('niveles', () {
    test('Nuevo, Frecuente y Experto según los puntos acumulados', () {
      expect(NivelColaborador.desdePuntos(0), NivelColaborador.nuevo);
      expect(NivelColaborador.desdePuntos(99), NivelColaborador.nuevo);
      expect(NivelColaborador.desdePuntos(100), NivelColaborador.frecuente);
      expect(NivelColaborador.desdePuntos(499), NivelColaborador.frecuente);
      expect(NivelColaborador.desdePuntos(500), NivelColaborador.experto);
      expect(NivelColaborador.desdePuntos(100000), NivelColaborador.experto);
    });

    test('un valor negativo cuenta como Nuevo', () {
      expect(NivelColaborador.desdePuntos(-5), NivelColaborador.nuevo);
    });

    test('los puntos que suman al llegar al mínimo suben el nivel', () {
      var acumulados = 95;
      expect(NivelColaborador.desdePuntos(acumulados), NivelColaborador.nuevo);

      acumulados += PuntosReglas.puntosBase; // un reporte más: 105
      expect(
          NivelColaborador.desdePuntos(acumulados), NivelColaborador.frecuente);
    });

    test('el nivel guardado en la base se lee por su número', () {
      expect(NivelColaborador.desdeNumero(1), NivelColaborador.nuevo);
      expect(NivelColaborador.desdeNumero(2), NivelColaborador.frecuente);
      expect(NivelColaborador.desdeNumero(3), NivelColaborador.experto);
      expect(NivelColaborador.desdeNumero(99), NivelColaborador.nuevo);
    });

    test('cada nivel conoce el siguiente; Experto es el último', () {
      expect(NivelColaborador.nuevo.siguiente, NivelColaborador.frecuente);
      expect(NivelColaborador.frecuente.siguiente, NivelColaborador.experto);
      expect(NivelColaborador.experto.siguiente, isNull);
    });

    test('los nombres son los del backlog', () {
      expect(NivelColaborador.values.map((n) => n.nombre),
          ['Nuevo', 'Frecuente', 'Experto']);
    });
  });

  group('progreso hacia el siguiente nivel', () {
    test('es la fracción del tramo recorrido', () {
      expect(NivelColaborador.nuevo.progreso(0), 0);
      expect(NivelColaborador.nuevo.progreso(50), 0.5);
      expect(NivelColaborador.frecuente.progreso(300), 0.5);
    });

    test('cuántos puntos faltan', () {
      expect(NivelColaborador.nuevo.puntosParaSiguiente(40), 60);
      expect(NivelColaborador.frecuente.puntosParaSiguiente(450), 50);
      expect(NivelColaborador.experto.puntosParaSiguiente(900), 0);
    });

    test('en el último nivel el progreso es completo', () {
      expect(NivelColaborador.experto.progreso(900), 1);
    });

    test('ResumenPuntos lo calcula con sus puntos acumulados', () {
      const resumen = ResumenPuntos(
        saldo: 20,
        acumulados: 150,
        nivel: NivelColaborador.frecuente,
        reputacion: 7,
      );

      expect(resumen.siguienteNivel, NivelColaborador.experto);
      expect(resumen.puntosParaSiguiente, 350);
      expect(resumen.progreso, closeTo(0.125, 0.0001));
    });

    test('el colaborador recién activado parte de cero', () {
      expect(ResumenPuntos.inicial.saldo, 0);
      expect(ResumenPuntos.inicial.nivel, NivelColaborador.nuevo);
      expect(ResumenPuntos.inicial.reputacion, 0);
    });
  });
}
