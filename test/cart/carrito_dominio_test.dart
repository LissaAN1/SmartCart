import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/carrito_reglas.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/catalog/data/source/producto_con_comercio_mapper.dart';

import '../support/fakes.dart';
import '../support/fakes_cliente.dart';

Matcher _falla([String? contiene]) => throwsA(
      isA<AuthFailure>().having(
        (e) => e.message,
        'message',
        contiene == null ? isNotEmpty : contains(contiene),
      ),
    );

void main() {
  group('CarritoReglas', () {
    test('la cantidad va de 1 a 99 y el carrito admite 100 productos', () {
      expect(CarritoReglas.cantidadMin, 1);
      expect(CarritoReglas.cantidadMax, 99);
      expect(CarritoReglas.productosMax, 100);
      expect(CarritoReglas.cantidadValida(0), isFalse);
      expect(CarritoReglas.cantidadValida(1), isTrue);
      expect(CarritoReglas.cantidadValida(99), isTrue);
      expect(CarritoReglas.cantidadValida(100), isFalse);
    });
  });

  group('ResumenCarrito', () {
    test('cuenta los productos (líneas) y las unidades (suma de cantidades)', () {
      final items = [
        const ItemCarrito(producto: arrozCliente, cantidad: 3),
        const ItemCarrito(producto: lecheCliente, cantidad: 2),
      ];

      expect(items.productos, 2);
      expect(items.unidades, 5);
    });

    test('un carrito vacío tiene cero de todo', () {
      expect(<ItemCarrito>[].productos, 0);
      expect(<ItemCarrito>[].unidades, 0);
    });

    test('conCantidad no cambia el producto', () {
      const item = ItemCarrito(producto: arrozCliente, cantidad: 1);

      final nuevo = item.conCantidad(4);

      expect(nuevo.cantidad, 4);
      expect(nuevo.idProducto, 'p1');
      expect(item.cantidad, 1);
    });
  });

  group('Filas de las funciones SQL', () {
    test('productoConComercioFromRow arma el producto con su comercio', () {
      final p = productoConComercioFromRow({
        'id_producto': 'p9',
        'id_categoria': 'k1',
        'nombre': 'Aceite 1 L',
        'marca': 'Premier',
        'codigo_barras': '7701111111111',
        'categoria': 'Super',
        'id_comercio': 'c7',
        'comercio': 'La Paila',
      });

      expect(p.id, 'p9');
      expect(p.producto.nombre, 'Aceite 1 L');
      expect(p.producto.marca, 'Premier');
      expect(p.producto.categoria, 'Super');
      expect(p.producto.idCategoria, 'k1');
      expect(p.idComercio, 'c7');
      expect(p.comercio, 'La Paila');
    });

    test('tolera marca y código vacíos', () {
      final p = productoConComercioFromRow({
        'id_producto': 'p9',
        'id_categoria': 'k1',
        'nombre': 'Sal',
        'marca': null,
        'codigo_barras': null,
        'categoria': null,
        'id_comercio': 'c7',
        'comercio': 'La Paila',
      });

      expect(p.producto.marca, isNull);
      expect(p.producto.codigoBarras, isNull);
      expect(p.producto.categoria, '');
    });

    test('comercioResumenFromRow arma el resumen del comercio', () {
      final c = comercioResumenFromRow({
        'id_comercio': 'c7',
        'nombre': 'La Paila',
        'direccion': 'Calle 1',
        'ciudad': 'Cali',
      });

      expect(c.id, 'c7');
      expect(c.nombre, 'La Paila');
      expect(c.direccion, 'Calle 1');
      expect(c.ciudad, 'Cali');
    });
  });

  group('GetClienteActivoUseCase', () {
    late TestEnv env;
    setUp(() => env = TestEnv());

    test('devuelve el id de quien tiene el perfil de cliente', () async {
      env.iniciarSesionComoCliente();

      expect(await env.clienteActivo(), 'u1');
    });

    test('sin sesión pide iniciarla', () async {
      await expectLater(env.clienteActivo(), _falla('Inicia sesión'));
    });

    test('quien no es cliente no puede usar el carrito', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(env.clienteActivo(), _falla('como cliente'));
    });
  });

  group('AgregarAlCarritoUseCase · escenario 1: agregar un producto', () {
    late TestEnv env;
    setUp(() => env = TestEnv()..iniciarSesionComoCliente());

    test('lo agrega con cantidad 1', () async {
      final cantidad = await env.agregarAlCarrito('p1');

      expect(cantidad, 1);
      final lineas = env.cliente.carrito.lineas;
      expect(lineas.single.idProducto, 'p1');
      expect(lineas.single.cantidad, 1);
    });

    test('si ya estaba, no crea otra línea: suma 1 a la cantidad', () async {
      await env.agregarAlCarrito('p1');
      final cantidad = await env.agregarAlCarrito('p1');

      expect(cantidad, 2);
      expect(env.cliente.carrito.lineas.length, 1);
      expect(env.cliente.carrito.lineas.single.cantidad, 2);
    });

    test('productos distintos son líneas distintas', () async {
      await env.agregarAlCarrito('p1');
      await env.agregarAlCarrito('p2');

      expect(env.cliente.carrito.lineas.map((l) => l.idProducto), ['p2', 'p1']);
    });

    test('un id vacío se rechaza sin tocar el carrito', () async {
      await expectLater(env.agregarAlCarrito('  '), _falla('Elige un producto'));

      expect(env.cliente.carrito.agregarCalls, 0);
    });

    test('un producto que ya no existe se rechaza', () async {
      await expectLater(env.agregarAlCarrito('p-borrado'), _falla('ya no está disponible'));

      expect(env.cliente.carrito.lineas, isEmpty);
    });

    test('quien no es cliente no puede agregar', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(env.agregarAlCarrito('p1'), _falla('como cliente'));

      expect(env.cliente.carrito.agregarCalls, 0);
    });

    test('99 unidades es el máximo por producto', () async {
      for (var i = 0; i < 99; i++) {
        await env.agregarAlCarrito('p1');
      }

      await expectLater(env.agregarAlCarrito('p1'), _falla('99 unidades'));

      expect(env.cliente.carrito.lineas.single.cantidad, 99);
    });

    test('el carrito admite 100 productos distintos y no uno más', () async {
      for (var i = 0; i < 100; i++) {
        env.cliente.carrito.disponibles['x$i'] = arrozCliente;
        await env.agregarAlCarrito('x$i');
      }

      await expectLater(env.agregarAlCarrito('p2'), _falla('carrito está lleno'));

      expect(env.cliente.carrito.lineas.length, 100);
    });
  });

  group('CambiarCantidadCarritoUseCase · escenario 2: cambiar la cantidad', () {
    late TestEnv env;
    setUp(() async {
      env = TestEnv()..iniciarSesionComoCliente();
      await env.agregarAlCarrito('p1');
    });

    test('el carrito se actualiza con la cantidad nueva', () async {
      await env.cambiarCantidadCarrito('p1', 5);

      expect(env.cliente.carrito.lineas.single.cantidad, 5);
    });

    test('se puede bajar la cantidad', () async {
      await env.cambiarCantidadCarrito('p1', 5);
      await env.cambiarCantidadCarrito('p1', 2);

      expect(env.cliente.carrito.lineas.single.cantidad, 2);
    });

    test('los extremos 1 y 99 son válidos', () async {
      await env.cambiarCantidadCarrito('p1', 99);
      expect(env.cliente.carrito.lineas.single.cantidad, 99);

      await env.cambiarCantidadCarrito('p1', 1);
      expect(env.cliente.carrito.lineas.single.cantidad, 1);
    });

    test('menos de 1 se rechaza y manda a usar "Quitar"', () async {
      await expectLater(env.cambiarCantidadCarrito('p1', 0), _falla('Quitar'));
      await expectLater(env.cambiarCantidadCarrito('p1', -3), _falla('Quitar'));

      expect(env.cliente.carrito.lineas.single.cantidad, 1);
      expect(env.cliente.carrito.cambiarCalls, 0);
    });

    test('más de 99 se rechaza', () async {
      await expectLater(env.cambiarCantidadCarrito('p1', 100), _falla('99'));

      expect(env.cliente.carrito.lineas.single.cantidad, 1);
    });

    test('una línea que ya no existe se avisa', () async {
      await expectLater(
        env.cambiarCantidadCarrito('p2', 3),
        _falla('ya no está en tu carrito'),
      );
    });

    test('quien no es cliente no puede cambiarla', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(env.cambiarCantidadCarrito('p1', 3), _falla('como cliente'));
    });
  });

  group('QuitarDelCarritoUseCase', () {
    late TestEnv env;
    setUp(() async {
      env = TestEnv()..iniciarSesionComoCliente();
      await env.agregarAlCarrito('p1');
      await env.agregarAlCarrito('p2');
    });

    test('quita solo ese producto', () async {
      await env.quitarDelCarrito('p1');

      expect(env.cliente.carrito.lineas.map((l) => l.idProducto), ['p2']);
    });

    test('quitar algo que no está no falla', () async {
      await env.quitarDelCarrito('p3');

      expect(env.cliente.carrito.lineas.length, 2);
    });

    test('quien no es cliente no puede quitar', () async {
      env.iniciarSesionCon({UserRole.comercio});

      await expectLater(env.quitarDelCarrito('p1'), _falla('como cliente'));

      expect(env.cliente.carrito.lineas.length, 2);
    });
  });

  group('GetCarritoUseCase · el carrito se recupera', () {
    test('devuelve lo guardado, con la cantidad de cada producto', () async {
      final env = TestEnv()..iniciarSesionComoCliente();
      await env.agregarAlCarrito('p1');
      await env.agregarAlCarrito('p1');
      await env.agregarAlCarrito('p2');

      final carrito = await env.getCarrito();

      expect(carrito.productos, 2);
      expect(carrito.unidades, 3);
      expect(carrito.firstWhere((i) => i.idProducto == 'p1').cantidad, 2);
    });

    test('un carrito nuevo está vacío', () async {
      final env = TestEnv()..iniciarSesionComoCliente();

      expect(await env.getCarrito(), isEmpty);
    });

    test('quien no es cliente no lo lee', () async {
      final env = TestEnv()..iniciarSesionCon({UserRole.comercio});

      await expectLater(env.getCarrito(), _falla('como cliente'));
    });
  });
}
