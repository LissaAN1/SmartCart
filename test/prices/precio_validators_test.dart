import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';

void main() {
  group('leerPesos', () {
    test('acepta números con punto de miles y símbolo', () {
      expect(PrecioValidators.leerPesos('2500'), 2500);
      expect(PrecioValidators.leerPesos('2.500'), 2500);
      expect(PrecioValidators.leerPesos(r'$ 12.500'), 12500);
    });

    test('rechaza letras, vacío y decimales', () {
      expect(PrecioValidators.leerPesos('abc'), isNull);
      expect(PrecioValidators.leerPesos(''), isNull);
      expect(PrecioValidators.leerPesos('2500,50'), isNull);
    });
  });

  group('precio', () {
    test('un valor positivo en pesos es válido', () {
      expect(PrecioValidators.precio('2.500'), isNull);
    });

    test('vacío pide escribirlo', () {
      expect(PrecioValidators.precio('  '), 'Escribe el precio');
    });

    test('cero o negativo no son válidos', () {
      expect(PrecioValidators.precio('0'), contains('mayor a cero'));
      expect(PrecioValidators.valor(-10), contains('mayor a cero'));
    });

    test('con centavos pide quitarlos', () {
      expect(PrecioValidators.precio('2500,50'), contains('sin centavos'));
    });

    test('con letras pide solo números', () {
      expect(PrecioValidators.precio('dos mil'), contains('solo números'));
    });

    test('no supera el tope', () {
      expect(PrecioValidators.precio('100.000.001'), contains('superar'));
      expect(PrecioValidators.valor(PrecioValidators.precioMax), isNull);
    });
  });

  group('precioPromocional', () {
    test('debe ser menor que el precio normal', () {
      expect(PrecioValidators.precioPromocional('2.000', 2500), isNull);
      expect(
        PrecioValidators.precioPromocional('2.500', 2500),
        contains('menos que el precio normal'),
      );
    });

    test('sin precio normal pide registrarlo primero', () {
      expect(
        PrecioValidators.precioPromocional('2.000', null),
        contains('precio normal'),
      );
    });
  });

  group('fechas', () {
    final hoy = DateTime(2026, 11, 15, 10);

    test('inicio y fin válidos, incluso el mismo día', () {
      expect(PrecioValidators.fechas(hoy, hoy, hoy), isNull);
      expect(
        PrecioValidators.fechas(
            DateTime(2026, 11, 20), DateTime(2026, 11, 30), hoy),
        isNull,
      );
    });

    test('faltan fechas', () {
      expect(PrecioValidators.fechas(null, hoy, hoy), contains('Elige'));
    });

    test('el fin no puede ser anterior al inicio', () {
      expect(
        PrecioValidators.fechas(
            DateTime(2026, 11, 20), DateTime(2026, 11, 18), hoy),
        contains('posterior'),
      );
    });

    test('no se puede crear una promoción que ya terminó', () {
      expect(
        PrecioValidators.fechas(
            DateTime(2026, 11, 1), DateTime(2026, 11, 14), hoy),
        contains('ya habría terminado'),
      );
    });
  });
}
