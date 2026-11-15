import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';

void main() {
  group('ProductoValidators', () {
    test('el nombre es obligatorio y va de 3 a 100 caracteres', () {
      expect(ProductoValidators.nombre(null), isNotNull);
      expect(ProductoValidators.nombre('   '), isNotNull);
      expect(ProductoValidators.nombre('ab'), isNotNull);
      expect(ProductoValidators.nombre('Sal'), isNull);
      expect(ProductoValidators.nombre('a' * 100), isNull);
      expect(ProductoValidators.nombre('a' * 101), isNotNull);
    });

    test('el nombre se mide sin los espacios de los bordes', () {
      expect(ProductoValidators.nombre('  ab  '), isNotNull);
    });

    test('la marca es opcional pero tiene un máximo de 60 caracteres', () {
      expect(ProductoValidators.marca(null), isNull);
      expect(ProductoValidators.marca(''), isNull);
      expect(ProductoValidators.marca('Diana'), isNull);
      expect(ProductoValidators.marca('a' * 60), isNull);
      expect(ProductoValidators.marca('a' * 61), isNotNull);
    });

    test('el código de barras es opcional y, si se escribe, son 8 a 14 dígitos',
        () {
      expect(ProductoValidators.codigoBarras(null), isNull);
      expect(ProductoValidators.codigoBarras(''), isNull);
      expect(ProductoValidators.codigoBarras('1234567'), isNotNull);
      expect(ProductoValidators.codigoBarras('12345678'), isNull);
      expect(ProductoValidators.codigoBarras('7701234567890'), isNull);
      expect(ProductoValidators.codigoBarras('12345678901234'), isNull);
      expect(ProductoValidators.codigoBarras('123456789012345'), isNotNull);
      expect(ProductoValidators.codigoBarras('77012345A7890'), isNotNull);
    });

    test('la categoría es obligatoria', () {
      expect(ProductoValidators.categoria(null), isNotNull);
      expect(ProductoValidators.categoria(''), isNotNull);
      expect(ProductoValidators.categoria('cat-super'), isNull);
    });

    test('datos devuelve el primer error o null si todo es válido', () {
      const valido = ProductoDatos(
        nombre: 'Arroz blanco',
        marca: 'Diana',
        codigoBarras: '7701234567890',
        idCategoria: 'cat-super',
      );
      expect(ProductoValidators.datos(valido), isNull);

      const sinCategoria = ProductoDatos(nombre: 'Arroz blanco', idCategoria: '');
      expect(ProductoValidators.datos(sinCategoria), 'Elige una categoría');

      const sinNombre = ProductoDatos(nombre: '', idCategoria: '');
      expect(ProductoValidators.datos(sinNombre), 'Escribe el nombre del producto');
    });
  });
}
