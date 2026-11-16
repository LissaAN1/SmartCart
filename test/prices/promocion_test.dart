import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';

final _promo = Promocion(
  idProducto: 'p1',
  precioPromocional: 2000,
  inicio: DateTime(2026, 11, 10),
  fin: DateTime(2026, 11, 20),
);

final _ficha = FichaPrecio(
  precio: PrecioProducto(
    idProducto: 'p1',
    precio: 2500,
    disponible: true,
    fuente: FuentePrecio.comercio,
    actualizadoEn: DateTime(2026, 11, 1),
  ),
  promocion: _promo,
);

void main() {
  group('Promocion · vigencia', () {
    test('antes del inicio está programada', () {
      expect(_promo.estadoEn(DateTime(2026, 11, 9, 23)),
          EstadoPromocion.programada);
    });

    test('vale desde el inicio hasta el fin, ambos incluidos', () {
      expect(_promo.vigenteEn(DateTime(2026, 11, 10, 0, 1)), isTrue);
      expect(_promo.vigenteEn(DateTime(2026, 11, 20, 23, 59)), isTrue);
    });

    test('después del fin está vencida', () {
      expect(_promo.estadoEn(DateTime(2026, 11, 21)), EstadoPromocion.vencida);
    });
  });

  group('FichaPrecio · precio mostrado', () {
    test('con la promoción vigente se muestra el precio promocional', () {
      expect(_ficha.precioMostrado(DateTime(2026, 11, 15)), 2000);
    });

    test('escenario 3: con la promoción vencida se muestra el precio normal',
        () {
      final ahora = DateTime(2026, 11, 25);
      expect(_ficha.promocionVigente(ahora), isNull);
      expect(_ficha.precioMostrado(ahora), 2500);
    });

    test('sin precio no hay nada que mostrar', () {
      expect(
          const FichaPrecio().precioMostrado(DateTime(2026, 11, 15)), isNull);
    });

    test('copyWith puede quitar la promoción', () {
      expect(_ficha.copyWith(sinPromocion: true).promocion, isNull);
      expect(_ficha.copyWith().promocion, same(_promo));
    });
  });

  test('FuentePrecio lee el código de la base', () {
    expect(FuentePrecio.desdeCodigo('colaborador'), FuentePrecio.colaborador);
    expect(FuentePrecio.desdeCodigo('otra'), FuentePrecio.comercio);
    expect(FuentePrecio.comercio.etiqueta, 'Comercio');
  });
}
