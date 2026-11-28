import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/reporte_reglas.dart';
import 'package:smartcart/features/reportes/domain/validacion_reglas.dart';

/// HU-15: las reglas con las que el sistema revisa un reporte. La base aplica
/// las mismas (`revisar_reporte`); estas pruebas fijan lo que dice el
/// backlog: ubicación, evidencia y coherencia con el historial.
void main() {
  group('regla de ubicación', () {
    test('un reporte a más de 150 m se rechaza con su motivo, y es falso', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 151,
        tieneFoto: true,
        precio: 4900,
        precioReferencia: 4900,
      );

      expect(r.estado, EstadoReporte.rechazado);
      expect(r.motivo, ValidacionReglas.motivoUbicacion);
      expect(r.esFalso, isTrue);
      expect(r.requiereConfirmacion, isFalse);
    });

    test('a 150 m justos todavía cumple', () {
      final r = ValidacionReglas.revisar(
        distanciaM: ReporteReglas.radioMaximoM,
        tieneFoto: true,
        precio: 4900,
        precioReferencia: 4900,
      );

      expect(r.estado, EstadoReporte.validado);
    });
  });

  group('regla de evidencia', () {
    test('sin foto se rechaza con su motivo, y es falso', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 20,
        tieneFoto: false,
        precio: 4900,
      );

      expect(r.estado, EstadoReporte.rechazado);
      expect(r.motivo, ValidacionReglas.motivoEvidencia);
      expect(r.esFalso, isTrue);
    });

    test('la ubicación se revisa antes que la evidencia', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 500,
        tieneFoto: false,
        precio: 4900,
      );

      expect(r.motivo, ValidacionReglas.motivoUbicacion);
    });
  });

  group('regla de coherencia con el historial', () {
    test('un precio parecido al registrado se valida', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 20,
        tieneFoto: true,
        precio: 5200,
        precioReferencia: 4900,
      );

      expect(r.estado, EstadoReporte.validado);
      expect(r.motivo, isNull);
      expect(r.requiereConfirmacion, isFalse);
      expect(r.esFalso, isFalse);
    });

    test('un precio muy distinto queda pendiente hasta que lo confirmen', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 20,
        tieneFoto: true,
        precio: 8000,
        precioReferencia: 4900,
      );

      expect(r.estado, EstadoReporte.pendiente);
      expect(r.requiereConfirmacion, isTrue);
      expect(r.motivo, ValidacionReglas.motivoConfirmacion(4900));
      expect(r.esFalso, isFalse);
    });

    test('también cuando el precio reportado es mucho menor', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 20,
        tieneFoto: true,
        precio: 1000,
        precioReferencia: 4900,
      );

      expect(r.requiereConfirmacion, isTrue);
    });

    test('exactamente 30 % de diferencia todavía se valida', () {
      expect(ValidacionReglas.esMuyDistinto(130, 100), isFalse);
      expect(ValidacionReglas.esMuyDistinto(70, 100), isFalse);
      expect(ValidacionReglas.esMuyDistinto(131, 100), isTrue);
      expect(ValidacionReglas.esMuyDistinto(69, 100), isTrue);
    });

    test('un producto sin precio no tiene con qué compararse: se valida', () {
      final r = ValidacionReglas.revisar(
        distanciaM: 20,
        tieneFoto: true,
        precio: 99999,
      );

      expect(r.estado, EstadoReporte.validado);
      expect(ValidacionReglas.esMuyDistinto(99999, null), isFalse);
      expect(ValidacionReglas.esMuyDistinto(99999, 0), isFalse);
    });
  });

  group('diferenciaRelativa', () {
    test('es la fracción del precio registrado', () {
      expect(ValidacionReglas.diferenciaRelativa(150, 100), 0.5);
      expect(ValidacionReglas.diferenciaRelativa(50, 100), 0.5);
      expect(ValidacionReglas.diferenciaRelativa(100, 100), 0);
    });

    test('ReportePorConfirmar la expone, o null si no había precio', () {
      final con = ReportePorConfirmar(
        id: 'r1',
        producto: 'Arroz',
        establecimiento: 'La Esquina',
        precio: 8000,
        precioActual: 4000,
        creadoEn: DateTime(2026, 11, 20),
      );
      final sin = ReportePorConfirmar(
        id: 'r2',
        producto: 'Arroz',
        establecimiento: 'La Esquina',
        precio: 8000,
        creadoEn: DateTime(2026, 11, 20),
      );

      expect(con.diferencia, 1.0);
      expect(sin.diferencia, isNull);
    });
  });

  group('estados del reporte', () {
    test('pendiente, validado y rechazado se leen de la base', () {
      expect(EstadoReporte.fromDbName('pendiente'), EstadoReporte.pendiente);
      expect(EstadoReporte.fromDbName('validado'), EstadoReporte.validado);
      expect(EstadoReporte.fromDbName('rechazado'), EstadoReporte.rechazado);
    });

    test('un estado desconocido nunca se muestra como validado', () {
      expect(EstadoReporte.fromDbName('otro'), EstadoReporte.pendiente);
    });
  });
}
