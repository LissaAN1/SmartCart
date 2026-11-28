import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comparacion/domain/comparador_carrito.dart';
import 'package:smartcart/features/comparacion/domain/entities/alternativa.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';
import 'package:smartcart/features/comparacion/domain/usecases/comparacion_usecases.dart';
import 'package:smartcart/features/comparacion/domain/valor_carrito.dart';

import '../support/fakes_comparacion.dart';
import '../support/fakes_ubicacion.dart';

Alternativa _alt(ResultadoComparacion r, CriterioCompra c) => r.alternativas[c]!;

/// Comercio elegido para cada producto del carrito.
Map<String, String> _dondeCompra(Alternativa a) => {
      for (final i in a.items) i.linea.idProducto: i.oferta.idComercio,
    };

void main() {
  group('ComparacionReglas', () {
    test('el factor de Calidad/precio va de 1 (5 estrellas) a 1,2 (1 estrella) '
        'y sin calificaciones cuenta como 3', () {
      expect(ComparacionReglas.factorCalidad(5), 1.0);
      expect(ComparacionReglas.factorCalidad(1), closeTo(1.2, 1e-9));
      expect(ComparacionReglas.factorCalidad(null),
          ComparacionReglas.factorCalidad(3));
      // Valores fuera de rango no se salen de los límites.
      expect(ComparacionReglas.factorCalidad(9), 1.0);
    });
  });

  group('escenario 1 · Ahorro', () {
    test('cada producto donde es más barato, con el costo y el ahorro', () {
      final r = ComparadorCarrito.comparar(
          lineas: carritoEjemplo(), cliente: ubicacionCliente);
      final a = _alt(r, CriterioCompra.ahorro);

      expect(_dondeCompra(a), {
        'arroz-a': 'C',
        'leche-a': 'B',
        'cafe-b': 'B',
        'pan-a': 'A',
      });
      expect(a.total, 29900);
      expect(a.totalActual, 32100);
      expect(a.ahorro, 2200);
      expect(a.establecimientos, 3);
    });

    test('la distancia total suma la del cliente a cada comercio', () {
      final r = ComparadorCarrito.comparar(
          lineas: carritoEjemplo(), cliente: ubicacionCliente);
      final a = _alt(r, CriterioCompra.ahorro);

      // ~0,6 + ~3,3 + ~7,8 km.
      expect(a.distanciaTotalM, closeTo(11676, 5));
      expect(a.comercios.every((c) => c.distanciaM != null), isTrue);
    });

    test('sin la ubicación del cliente se compara igual y la distancia no '
        'está disponible', () {
      final r = ComparadorCarrito.comparar(lineas: carritoEjemplo());
      final a = _alt(r, CriterioCompra.ahorro);

      expect(a.total, 29900);
      expect(a.distanciaTotalM, isNull);
    });

    test('un comercio sin ubicación deja la distancia total como no '
        'disponible', () {
      final r = ComparadorCarrito.comparar(
        lineas: [
          linea('x', 'X', 1, [oferta('x', 'A', 100, sinUbicacion: true)]),
        ],
        cliente: ubicacionCliente,
      );

      expect(_alt(r, CriterioCompra.ahorro).distanciaTotalM, isNull);
    });
  });

  group('escenario 2 · Comodidad', () {
    test('el menor número de comercios que cubre todo', () {
      final r = ComparadorCarrito.comparar(
          lineas: carritoEjemplo(), cliente: ubicacionCliente);
      final a = _alt(r, CriterioCompra.comodidad);

      expect(a.establecimientos, 1);
      expect(a.comercios.single.idComercio, 'A');
      expect(a.total, 32600);
      // Cuesta más que el carrito actual: el ahorro es 0, nunca negativo.
      expect(a.ahorro, 0);
    });

    test('con empate en el número de comercios elige el de menor costo', () {
      final r = ComparadorCarrito.comparar(lineas: [
        linea('x', 'X', 1, [oferta('x', 'A', 1000), oferta('x2', 'B', 900)]),
        linea('y', 'Y', 1, [oferta('y', 'A', 1000), oferta('y2', 'B', 950)]),
      ]);
      final a = _alt(r, CriterioCompra.comodidad);

      expect(a.establecimientos, 1);
      expect(a.comercios.single.idComercio, 'B');
      expect(a.total, 1850);
    });

    test('si ningún comercio tiene todo, usa el par más barato', () {
      final r = ComparadorCarrito.comparar(lineas: [
        linea('x', 'X', 1, [oferta('x', 'A', 1000), oferta('x2', 'B', 800)]),
        linea('y', 'Y', 1, [oferta('y', 'C', 500)]),
        linea('z', 'Z', 1, [oferta('z', 'A', 300), oferta('z2', 'C', 200)]),
      ]);
      final a = _alt(r, CriterioCompra.comodidad);

      // A+C cubre todo por 1000+500+200 y B+C por 800+500+200.
      expect(a.establecimientos, 2);
      expect(a.comercios.map((c) => c.idComercio).toSet(), {'B', 'C'});
      expect(a.total, 1500);
    });

    test('con muchísimos comercios usa el método rápido y cubre todo', () {
      // 30 comercios: 4 productos únicos de C1..C4 y uno que está en todos.
      // Probar los grupos de 4 superaría el límite de combinaciones.
      final comun = [
        for (var i = 1; i <= 30; i++) oferta('comun-$i', 'C$i', 1000 + i),
      ];
      final lineas = [
        for (var i = 1; i <= 4; i++)
          linea('u$i', 'Único $i', 1, [oferta('u$i', 'C$i', 500)]),
        linea('comun-1', 'Común', 1, comun),
      ];
      final r = ComparadorCarrito.comparar(lineas: lineas);
      final a = _alt(r, CriterioCompra.comodidad);

      expect(a.establecimientos, 4);
      expect(a.items.length, 5);
    });
  });

  group('escenario 3 · Calidad/precio', () {
    test('combina el precio con la calificación del comercio', () {
      final r = ComparadorCarrito.comparar(
          lineas: carritoEjemplo(), cliente: ubicacionCliente);
      final a = _alt(r, CriterioCompra.calidadPrecio);

      // El arroz de C es el más barato (4.000), pero B (5 estrellas, 4.200)
      // gana: 4.200 × 1 < 4.000 × 1,1 (C sin calificaciones).
      expect(_dondeCompra(a), {
        'arroz-a': 'B',
        'leche-a': 'B',
        'cafe-b': 'B',
        'pan-a': 'A',
      });
      expect(a.total, 30300);
      expect(a.ahorro, 1800);
      final b = a.comercios.firstWhere((c) => c.idComercio == 'B');
      expect(b.calificacion, 5.0);
      expect(b.totalCalificaciones, 10);
    });

    test('una diferencia de precio grande sigue ganando a la calificación',
        () {
      final r = ComparadorCarrito.comparar(lineas: [
        linea('x', 'X', 1, [oferta('x', 'A', 1000), oferta('x2', 'B', 2000)]),
      ]);

      expect(_dondeCompra(_alt(r, CriterioCompra.calidadPrecio)), {'x': 'A'});
    });

    test('un comercio sin calificaciones lo indica', () {
      final r = ComparadorCarrito.comparar(lineas: carritoEjemplo());
      final c = _alt(r, CriterioCompra.ahorro)
          .comercios
          .firstWhere((c) => c.idComercio == 'C');

      expect(c.tieneCalificaciones, isFalse);
    });
  });

  group('escenario 4 · Distancia máxima', () {
    test('con 5 km el comercio de 7,8 km no entra en ninguna alternativa', () {
      final r = ComparadorCarrito.comparar(
        lineas: carritoEjemplo(),
        cliente: ubicacionCliente,
        distanciaMaxM: 5000,
      );

      for (final a in r.alternativas.values) {
        expect(a.comercios.map((c) => c.idComercio), isNot(contains('C')));
      }
      expect(_dondeCompra(_alt(r, CriterioCompra.ahorro))['arroz-a'], 'B');
    });

    test('un comercio sin ubicación queda fuera cuando hay distancia máxima',
        () {
      final r = ComparadorCarrito.comparar(
        lineas: [
          linea('x', 'X', 1, [
            oferta('x', 'A', 1000),
            oferta('x2', 'Z', 10, sinUbicacion: true),
          ]),
        ],
        cliente: ubicacionCliente,
        distanciaMaxM: 20000,
      );

      expect(_dondeCompra(_alt(r, CriterioCompra.ahorro)), {'x': 'A'});
    });
  });

  group('escenario 5 · Producto sin disponibilidad', () {
    test('avisa cuál falta y calcula con los demás', () {
      final lineas = [
        ...carritoEjemplo(),
        linea('sal', 'Sal 1 kg', 1, [oferta('sal', 'A', 1500, disponible: false)]),
        linea('miel', 'Miel', 1, []),
      ];
      final r = ComparadorCarrito.comparar(lineas: lineas);

      expect(r.faltantes.map((l) => l.nombre), ['Sal 1 kg', 'Miel']);
      expect(_alt(r, CriterioCompra.ahorro).items.length, 4);
    });

    test('con 1 km solo queda A: lo que solo está en B falta', () {
      final r = ComparadorCarrito.comparar(
        lineas: [
          linea('x', 'X', 1, [oferta('x', 'A', 1000)]),
          linea('y', 'Y', 1, [oferta('y', 'B', 1000)]),
        ],
        cliente: ubicacionCliente,
        distanciaMaxM: 1000,
      );

      expect(r.faltantes.map((l) => l.idProducto), ['y']);
    });

    test('si no hay nada disponible no hay alternativas', () {
      final r = ComparadorCarrito.comparar(lineas: [
        linea('x', 'X', 1, [oferta('x', 'A', 1000, disponible: false)]),
      ]);

      expect(r.sinAlternativas, isTrue);
      expect(r.faltantes, hasLength(1));
    });

    test('las ofertas agotadas no se eligen y de un comercio con el mismo '
        'producto dos veces queda la más barata', () {
      final r = ComparadorCarrito.comparar(lineas: [
        linea('x', 'X', 1, [
          oferta('x', 'A', 1000),
          oferta('x2', 'B', 500, disponible: false),
          oferta('x3', 'A', 800),
        ]),
      ]);
      final item = _alt(r, CriterioCompra.ahorro).items.single;

      expect(item.oferta.idProducto, 'x3');
    });
  });

  group('escenario 6 · Carrito vacío y caso de uso', () {
    final comparar = CompararCarritoUseCase();

    test('con el carrito vacío no se genera ninguna alternativa', () {
      expect(() => comparar(lineas: const []),
          throwsA(isA<AuthFailure>().having(
              (f) => f.message, 'mensaje', contains('vacío'))));
    });

    test('la distancia máxima exige la ubicación y un valor de 1 a 20 km', () {
      expect(() => comparar(lineas: carritoEjemplo(), distanciaMaxM: 5000),
          throwsA(isA<AuthFailure>()));
      expect(
          () => comparar(
              lineas: carritoEjemplo(),
              cliente: ubicacionCliente,
              distanciaMaxM: 50000),
          throwsA(isA<AuthFailure>()));
    });
  });

  group('ValorCarrito', () {
    ItemCarrito item(String id, int cantidad) => ItemCarrito(
          producto: ProductoConComercio(
            producto: Producto(
                id: id, nombre: id, idCategoria: 'k', categoria: 'Super'),
            idComercio: 'A',
            comercio: 'Super A',
          ),
          cantidad: cantidad,
        );

    test('suma el precio vigente por la cantidad y cuenta los que no tienen '
        'precio', () {
      final precios = {
        'arroz': PrecioLinea.de(
            oferta('arroz', 'A', 4000, enPromocion: true, precioNormal: 5000)),
        'leche': PrecioLinea.de(oferta('leche', 'A', 4100, disponible: false)),
      };
      final valor = ValorCarrito.de(
          [item('arroz', 2), item('leche', 1), item('pan', 1)], precios);

      expect(valor.total, 8000);
      expect(valor.sinPrecio, 2);
      expect(precios['arroz']!.enPromocion, isTrue);
      expect(precios['leche']!.agotado, isTrue);
    });

    test('el precio actual de una línea es el del producto del carrito', () {
      final l = carritoEjemplo().first;

      expect(l.ofertaActual?.idComercio, 'A');
      expect(l.precioActual, 5000);
      expect(
          const LineaComparable(
                  idProducto: 'x', nombre: 'X', cantidad: 1, ofertas: [])
              .precioActual,
          isNull);
    });
  });
}
