import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';

import '../support/fakes.dart';

const _arroz = ProductoDatos(
  nombre: 'Arroz blanco 500 g',
  marca: 'Diana',
  codigoBarras: '7701234567890',
  idCategoria: 'cat-super',
);

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

  group('GetComercioAprobadoUseCase', () {
    test('devuelve el comercio cuando está aprobado', () async {
      final comercio = await env.comercioAprobado();

      expect(comercio.id, 'c1');
    });

    test('sin sesión pide iniciarla', () async {
      env.auth.current = null;

      await expectLater(env.comercioAprobado(), _falla('Inicia sesión'));
    });

    test('sin comercio registrado pide registrarlo', () async {
      env.comercios.stored = null;

      await expectLater(env.comercioAprobado(), _falla('Registra tu comercio'));
    });

    test('escenario 2: un comercio pendiente debe esperar la aprobación',
        () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(env.comercioAprobado(), _falla('pendiente de aprobación'));
    });

    test('un comercio rechazado tampoco puede gestionar productos', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.rechazado);

      await expectLater(env.comercioAprobado(), _falla('rechazado'));
    });
  });

  group('CrearProductoUseCase · escenario 1', () {
    test('guarda el producto en el catálogo del comercio', () async {
      final producto = await env.crearProducto(_arroz);

      expect(producto.nombre, 'Arroz blanco 500 g');
      expect(producto.categoria, 'Super');
      expect(env.catalogo.creados.single.idComercio, 'c1');
      expect(env.catalogo.deComercio('c1').single.id, producto.id);
    });

    test('quita espacios y guarda null en lo opcional que quedó vacío',
        () async {
      await env.crearProducto(const ProductoDatos(
        nombre: '  Sal marina  ',
        marca: '   ',
        codigoBarras: '',
        idCategoria: 'cat-super',
      ));

      final guardado = env.catalogo.creados.single.datos;
      expect(guardado.nombre, 'Sal marina');
      expect(guardado.marca, isNull);
      expect(guardado.codigoBarras, isNull);
    });

    test('no guarda un producto inválido', () async {
      await expectLater(
        env.crearProducto(const ProductoDatos(nombre: 'ab', idCategoria: 'x')),
        _falla(),
      );
      await expectLater(
        env.crearProducto(const ProductoDatos(nombre: 'Arroz', idCategoria: '')),
        _falla('categoría'),
      );
      await expectLater(
        env.crearProducto(const ProductoDatos(
          nombre: 'Arroz',
          idCategoria: 'cat-super',
          codigoBarras: '123',
        )),
        _falla('dígitos'),
      );

      expect(env.catalogo.creados, isEmpty);
    });

    test('un comercio pendiente no puede crear productos', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(env.crearProducto(_arroz), _falla('pendiente'));

      expect(env.catalogo.creados, isEmpty);
    });

    test('un código de barras repetido en el comercio se rechaza', () async {
      await env.crearProducto(_arroz);

      await expectLater(env.crearProducto(_arroz), _falla('código de barras'));

      expect(env.catalogo.deComercio('c1').length, 1);
    });
  });

  group('EditarProductoUseCase', () {
    test('actualiza el producto', () async {
      final creado = await env.crearProducto(_arroz);

      final editado = await env.editarProducto(
        creado.id,
        const ProductoDatos(
          nombre: 'Arroz integral',
          idCategoria: 'cat-frutas',
        ),
      );

      expect(editado.nombre, 'Arroz integral');
      expect(editado.categoria, 'Frutas');
      expect(env.catalogo.deComercio('c1').single.nombre, 'Arroz integral');
    });

    test('valida antes de guardar y exige comercio aprobado', () async {
      final creado = await env.crearProducto(_arroz);

      await expectLater(
        env.editarProducto(creado.id, const ProductoDatos(nombre: '', idCategoria: 'x')),
        _falla(),
      );

      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);
      await expectLater(env.editarProducto(creado.id, _arroz), _falla('pendiente'));
    });
  });

  group('EliminarProductoUseCase', () {
    test('quita el producto del catálogo', () async {
      final creado = await env.crearProducto(_arroz);

      await env.eliminarProducto(creado.id);

      expect(env.catalogo.deComercio('c1'), isEmpty);
    });

    test('un comercio pendiente no puede eliminar', () async {
      final creado = await env.crearProducto(_arroz);
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(env.eliminarProducto(creado.id), _falla('pendiente'));

      expect(env.catalogo.deComercio('c1').length, 1);
    });
  });

  group('GetProductosUseCase · solo los productos del propio comercio', () {
    test('devuelve únicamente los productos de su comercio', () async {
      env.catalogo.precargar('c1', 2);
      env.catalogo.precargar('otro-comercio', 3);

      final pagina = await env.getProductos(const PageRequest());

      expect(pagina.items.length, 2);
      expect(pagina.items.every((p) => p.nombre.startsWith('Producto')), isTrue);
      expect(pagina.hasMore, isFalse);
    });

    test('se carga por páginas e indica si hay más', () async {
      env.catalogo.precargar('c1', 5);

      final primera = await env.getProductos(const PageRequest(pageSize: 2));
      expect(primera.items.length, 2);
      expect(primera.hasMore, isTrue);

      final ultima =
          await env.getProductos(const PageRequest(page: 2, pageSize: 2));
      expect(ultima.items.length, 1);
      expect(ultima.hasMore, isFalse);
    });

    test('un comercio pendiente no puede abrir el catálogo', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(
        env.getProductos(const PageRequest()),
        _falla('pendiente de aprobación'),
      );
    });
  });

  group('GetCategoriasUseCase', () {
    test('entrega las categorías disponibles', () async {
      final categorias = await env.getCategorias();

      expect(categorias.map((c) => c.nombre), ['Super', 'Frutas', 'Lácteos']);
    });
  });

  group('CargarProductosCsvUseCase · escenario 3', () {
    test('carga las filas válidas y reporta las que fallaron con su motivo',
        () async {
      const archivo = 'nombre,marca,codigo_barras,categoria\n'
          'Arroz blanco,Diana,7701234567890,Super\n'
          'ab,Marca,,Super\n'
          'Leche entera,Alpina,,lácteos\n'
          'Queso campesino,,,Charcutería\n'
          'Banano,,123,Frutas\n';

      final resultado = await env.cargarProductosCsv(archivo);

      expect(resultado.cargados, 2);
      expect(env.catalogo.deComercio('c1').map((p) => p.nombre),
          unorderedEquals(['Arroz blanco', 'Leche entera']));
      expect(resultado.errores.map((e) => e.fila), [3, 5, 6]);
      expect(resultado.errores[0].motivo, contains('mínimo'));
      expect(resultado.errores[1].motivo, contains('Charcutería'));
      expect(resultado.errores[2].motivo, contains('dígitos'));
    });

    test('la categoría se reconoce sin importar las mayúsculas', () async {
      final resultado = await env.cargarProductosCsv(
        'nombre,categoria\nLeche entera,LÁCTEOS\nMango,frutas\n',
      );

      expect(resultado.cargados, 2);
      expect(resultado.errores, isEmpty);
    });

    test('un código repetido dentro del archivo se reporta en la segunda fila',
        () async {
      final resultado = await env.cargarProductosCsv(
        'nombre,codigo_barras,categoria\n'
        'Arroz blanco,7701234567890,Super\n'
        'Arroz integral,7701234567890,Super\n',
      );

      expect(resultado.cargados, 1);
      expect(resultado.errores.single.fila, 3);
      expect(resultado.errores.single.motivo, contains('repetido'));
    });

    test('un código que ya tiene otro producto del comercio se reporta',
        () async {
      await env.crearProducto(_arroz);

      final resultado = await env.cargarProductosCsv(
        'nombre,codigo_barras,categoria\n'
        'Arroz blanco,7701234567890,Super\n'
        'Sal marina,7700000000001,Super\n',
      );

      expect(resultado.cargados, 1);
      expect(resultado.errores.single.fila, 2);
      expect(resultado.errores.single.motivo, contains('Ya tienes'));
    });

    test('si ninguna fila es válida no se guarda nada', () async {
      final resultado = await env.cargarProductosCsv(
        'nombre,categoria\nab,Super\nSal marina,Inexistente\n',
      );

      expect(resultado.cargados, 0);
      expect(resultado.errores.length, 2);
      expect(env.catalogo.crearVariosCalls, 0);
    });

    test('un archivo con formato inválido falla sin tocar el catálogo',
        () async {
      await expectLater(
        env.cargarProductosCsv('marca,codigo\nDiana,1\n'),
        _falla('"nombre" y "categoria"'),
      );

      expect(env.catalogo.crearVariosCalls, 0);
    });

    test('un comercio pendiente no puede cargar productos', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(
        env.cargarProductosCsv('nombre,categoria\nArroz blanco,Super\n'),
        _falla('pendiente'),
      );

      expect(env.catalogo.creados, isEmpty);
    });

    test('si la base falla al guardar, el error llega a quien llamó', () async {
      env.catalogo.crearVariosError = const AuthFailure('Sin conexión.');

      await expectLater(
        env.cargarProductosCsv('nombre,categoria\nArroz blanco,Super\n'),
        _falla('Sin conexión.'),
      );
    });
  });
}
