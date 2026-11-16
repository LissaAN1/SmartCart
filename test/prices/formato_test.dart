import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/core/utils/json_helpers.dart';

void main() {
  group('formatoCop', () {
    test('agrega el punto de miles', () {
      expect(formatoCop(2500), r'$ 2.500');
      expect(formatoCop(1234567), r'$ 1.234.567');
      expect(formatoCop(100000000), r'$ 100.000.000');
    });

    test('valores pequeños van sin punto', () {
      expect(formatoCop(0), r'$ 0');
      expect(formatoCop(900), r'$ 900');
    });

    test('un negativo lleva el signo antes del símbolo', () {
      expect(formatoCop(-1500), r'-$ 1.500');
    });
  });

  group('fechas', () {
    test('fechaCorta usa el mes abreviado', () {
      expect(fechaCorta(DateTime(2026, 11, 5)), '5 nov 2026');
    });

    test('fechaHora agrega la hora con dos dígitos', () {
      expect(fechaHora(DateTime(2026, 1, 15, 9, 7)), '15 ene 2026 · 09:07');
    });

    test('soloFecha quita la hora', () {
      expect(soloFecha(DateTime(2026, 11, 15, 23, 59)), DateTime(2026, 11, 15));
    });

    test('toSqlDate y parseSqlDate van y vuelven sin correr el día', () {
      final fecha = DateTime(2026, 3, 9);
      expect(toSqlDate(fecha), '2026-03-09');
      expect(parseSqlDate('2026-03-09'), fecha);
      expect(parseSqlDate(null), isNull);
    });
  });
}
