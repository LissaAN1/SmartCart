import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_foto_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';
import 'package:smartcart/features/catalog/presentation/bloc/catalogo_lista_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/presentation/widgets/historial_precios_card.dart';

import '../support/fakes.dart';

const _arroz = ProductoDatos(
  nombre: 'Arroz Diana Premium',
  marca: 'Diana',
  idCategoria: 'cat-super',
  stock: 45,
);

final _foto = ImagenProducto(bytes: Uint8List(10), extension: 'jpg');

Matcher _falla([String? contiene]) => throwsA(
      isA<AuthFailure>().having(
        (e) => e.message,
        'message',
        contiene == null ? isNotEmpty : contains(contiene),
      ),
    );

/// Producto ya guardado con precio y stock, en el catálogo y en los precios.
Producto _guardado(
  TestEnv env, {
  String id = 'p1',
  String nombre = 'Arroz Diana Premium',
  String idCategoria = 'cat-super',
  int precio = 4500,
  int stock = 45,
}) {
  final producto = Producto(
    id: id,
    nombre: nombre,
    idCategoria: idCategoria,
    categoria: 'Super',
    precio: precio,
    stock: stock,
  );
  env.catalogo.deComercio('c1').add(producto);
  env.precios.precargar(id, precio);
  return producto;
}

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  });

  group('Stock', () {
    test('el validador acepta vacío y enteros entre 0 y el tope', () {
      expect(ProductoValidators.stock(''), isNull);
      expect(ProductoValidators.stock('45'), isNull);
      expect(ProductoValidators.stock('-1'), contains('negativo'));
      expect(ProductoValidators.stock('4,5'), contains('enteros'));
      expect(ProductoValidators.stock('100001'), contains('máximo'));
    });

    test('10 unidades o menos es stock bajo', () {
      const base = Producto(
          id: 'p', nombre: 'x', idCategoria: 'c', categoria: 'Super');
      expect(base.copyWith(stock: 10).stockBajo, isTrue);
      expect(base.copyWith(stock: 11).stockBajo, isFalse);
    });
  });

  group('formatoCopCorto y mesCorto', () {
    test('montos cortos como en el resumen del diseño', () {
      expect(formatoCopCorto(900), r'$900');
      expect(formatoCopCorto(4500), r'$4.5k');
      expect(formatoCopCorto(420000), r'$420k');
      expect(formatoCopCorto(1250000), r'$1.3M');
    });

    test('mes abreviado con mayúscula', () {
      expect(mesCorto(7), 'Jul');
      expect(mesCorto(11), 'Nov');
    });
  });

  group('GuardarProductoUseCase', () {
    test('crea el producto con su stock y guarda el precio en un paso',
        () async {
      final producto =
          await env.guardarProducto(datos: _arroz, precio: 4500);

      expect(producto.stock, 45);
      expect(producto.precio, 4500);
      expect(env.catalogo.creados.single.datos.stock, 45);
      expect(env.precios.precios[producto.id]?.precio, 4500);
    });

    test('un precio inválido no deja el producto guardado a medias',
        () async {
      await expectLater(
        env.guardarProducto(datos: _arroz, precio: 0),
        _falla('mayor a cero'),
      );
      expect(env.catalogo.creados, isEmpty);
    });

    test('sin precio guarda solo el producto', () async {
      final producto = await env.guardarProducto(datos: _arroz);

      expect(producto.precio, isNull);
      expect(env.precios.guardados, isEmpty);
    });

    test('al editar sin cambiar el precio no escribe otro precio', () async {
      final actual = _guardado(env);

      final producto = await env.guardarProducto(
        editando: actual,
        datos: _arroz,
        precio: 4500,
      );

      expect(env.precios.guardados, isEmpty);
      expect(producto.precio, 4500);
    });

    test('con foto la sube a la carpeta del comercio', () async {
      final producto =
          await env.guardarProducto(datos: _arroz, foto: _foto);

      expect(env.catalogo.fotosSubidas.single.idComercio, 'c1');
      expect(producto.fotoUrl, contains('c1/'));
    });

    test('un comercio pendiente no puede guardar', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);

      await expectLater(
        env.guardarProducto(datos: _arroz, precio: 4500),
        _falla('pendiente de aprobación'),
      );
    });
  });

  group('GetEncabezadoCatalogoUseCase', () {
    test('trae las categorías y el resumen del inventario', () async {
      _guardado(env, id: 'p1', precio: 4500, stock: 45);
      _guardado(env, id: 'p2', precio: 3800, stock: 8);

      final encabezado = await env.getEncabezado();

      expect(encabezado.categorias, hasLength(3));
      expect(encabezado.resumen.totalProductos, 2);
      expect(encabezado.resumen.valorStock, 4500 * 45 + 3800 * 8);
      expect(encabezado.resumen.bajoStock, 1);
    });
  });

  group('ElegirFotoProductoUseCase', () {
    test('devuelve la foto elegida o null si se cancela', () async {
      expect(await env.elegirFoto(), isNull);
      env.selectorImagen.foto = _foto;
      expect(await env.elegirFoto(), same(_foto));
    });

    test('rechaza una foto de más de 5 MB', () async {
      env.selectorImagen.foto = ImagenProducto(
        bytes: Uint8List(ElegirFotoProductoUseCase.tamanoMaximo + 1),
        extension: 'png',
      );

      await expectLater(env.elegirFoto(), _falla('5 MB'));
    });
  });

  group('CatalogoListaBloc · búsqueda y categoría', () {
    test('filtra por texto (nombre o marca) y por categoría', () async {
      _guardado(env, id: 'p1', nombre: 'Arroz Diana');
      _guardado(env, id: 'p2', nombre: 'Leche entera', idCategoria: 'cat-lacteos');
      final bloc = env.productosBloc()..add(PaginatedStarted());
      await bloc.stream.firstWhere((s) => s.status == PaginatedStatus.success);

      bloc.add(FiltroCatalogoCambiado(const FiltroCatalogo(texto: 'arroz')));
      var state = await bloc.stream.firstWhere(
          (s) => s.status == PaginatedStatus.success && s.items.length == 1);
      expect(state.items.single.nombre, 'Arroz Diana');

      bloc.add(FiltroCatalogoCambiado(
          const FiltroCatalogo(idCategoria: 'cat-lacteos')));
      state = await bloc.stream.firstWhere((s) =>
          s.status == PaginatedStatus.success &&
          s.items.single.nombre == 'Leche entera');
      expect(bloc.filtro.idCategoria, 'cat-lacteos');
      await bloc.close();
    });

    test('un filtro que llega mientras carga se aplica al terminar', () async {
      _guardado(env, id: 'p1', nombre: 'Arroz Diana');
      _guardado(env, id: 'p2', nombre: 'Leche entera');
      final bloc = env.productosBloc()
        ..add(PaginatedStarted())
        ..add(FiltroCatalogoCambiado(const FiltroCatalogo(texto: 'leche')));

      final state = await bloc.stream.firstWhere((s) =>
          s.status == PaginatedStatus.success && s.items.length == 1);

      expect(state.items.single.nombre, 'Leche entera');
      await bloc.close();
    });

    test('PaginatedItemReplaced cambia una fila sin recargar', () async {
      final producto = _guardado(env);
      final bloc = env.productosBloc()..add(PaginatedStarted());
      await bloc.stream.firstWhere((s) => s.status == PaginatedStatus.success);
      final pedidos = env.catalogo.filtrosPedidos.length;

      bloc.add(PaginatedItemReplaced<Producto>(
        producto.copyWith(disponible: false),
        donde: (p) => p.id == producto.id,
      ));
      final state = await bloc.stream.first;

      expect(state.items.single.disponible, isFalse);
      expect(env.catalogo.filtrosPedidos.length, pedidos);
      await bloc.close();
    });
  });

  group('InventarioBloc', () {
    test('carga el encabezado', () async {
      _guardado(env);
      final bloc = env.inventarioBloc()..add(InventarioStarted());

      final state =
          await bloc.stream.firstWhere((s) => s.status == InventarioStatus.ready);

      expect(state.encabezado?.resumen.totalProductos, 1);
      await bloc.close();
    });

    test('escenario 2: el interruptor marca agotado y devuelve el producto',
        () async {
      final producto = _guardado(env);
      final bloc = env.inventarioBloc();

      bloc.add(DisponibilidadEnListaCambiada(producto, false));
      final state = await bloc.stream.firstWhere((s) => s.actualizado != null);

      expect(state.actualizado?.disponible, isFalse);
      expect(env.precios.precios['p1']?.disponible, isFalse);
      await bloc.close();
    });

    test('eliminar quita el producto y avisa para recargar', () async {
      final producto = _guardado(env);
      final bloc = env.inventarioBloc();

      bloc.add(ProductoEliminadoDeLista(producto));
      final state = await bloc.stream.firstWhere((s) => s.eliminado);

      expect(state.eliminado, isTrue);
      expect(env.catalogo.deComercio('c1'), isEmpty);
      await bloc.close();
    });

    test('un error se muestra una vez', () async {
      final producto = _guardado(env);
      env.precios.guardarError = const AuthFailure('Sin conexión');
      final bloc = env.inventarioBloc();

      bloc.add(DisponibilidadEnListaCambiada(producto, false));
      final state =
          await bloc.stream.firstWhere((s) => s.errorMessage != null);

      expect(state.errorMessage, 'Sin conexión');
      expect(state.cambiandoId, isNull);
      await bloc.close();
    });
  });

  group('ProductoFormBloc', () {
    test('al iniciar trae las categorías y el comercio', () async {
      final bloc = env.productoFormBloc()..add(ProductoFormStarted());

      final state = await bloc.stream
          .firstWhere((s) => s.status == ProductoFormStatus.ready);

      expect(state.comercio?.nombre, 'Minimercado La Esquina');
      expect(state.categorias, hasLength(3));
      await bloc.close();
    });

    test('la foto elegida se guarda con el producto', () async {
      env.selectorImagen.foto = _foto;
      final bloc = env.productoFormBloc()..add(ProductoFormStarted());
      await bloc.stream.firstWhere((s) => s.status == ProductoFormStatus.ready);

      bloc.add(ProductoFormFotoPedida());
      await bloc.stream.firstWhere((s) => s.foto != null);
      bloc.add(ProductoFormGuardado(_arroz, precio: 4500));
      await bloc.stream.firstWhere((s) => s.status == ProductoFormStatus.saved);

      expect(env.catalogo.fotosSubidas, hasLength(1));
      expect(env.precios.guardados.single.datos.precio, 4500);
      await bloc.close();
    });

    test('un error al elegir la foto deja el formulario listo', () async {
      env.selectorImagen.error = const AuthFailure('No pudimos leer la foto.');
      final bloc = env.productoFormBloc()..add(ProductoFormStarted());
      await bloc.stream.firstWhere((s) => s.status == ProductoFormStatus.ready);

      bloc.add(ProductoFormFotoPedida());
      final state = await bloc.stream.firstWhere((s) => s.errorMessage != null);

      expect(state.status, ProductoFormStatus.ready);
      expect(state.errorMessage, 'No pudimos leer la foto.');
      await bloc.close();
    });
  });

  group('Historial de precios', () {
    PrecioProducto actual(int precio) => PrecioProducto(
          idProducto: 'p1',
          precio: precio,
          disponible: true,
          fuente: FuentePrecio.comercio,
          actualizadoEn: DateTime(2026, 11, 10),
        );
    RegistroPrecio registro(int precio, DateTime fecha) => RegistroPrecio(
          precio: precio,
          disponible: true,
          fuente: FuentePrecio.comercio,
          registradoEn: fecha,
        );

    // Del más reciente al más antiguo, como llega de la base.
    final ficha = FichaPrecio(
      precio: actual(4600),
      historial: [
        registro(4600, DateTime(2026, 11, 10)),
        registro(5000, DateTime(2026, 9, 20)),
        registro(4200, DateTime(2026, 6, 1)),
      ],
    );
    final ahora = DateTime(2026, 11, 15);

    test('variación del mes: compara con el precio al empezar el mes', () {
      // 5000 → 4600: bajó 8 %.
      expect(ficha.variacionDelMes(ahora), closeTo(-8, 0.001));
    });

    test('variación del último cambio', () {
      expect(ficha.variacionUltimoCambio(), closeTo(-8, 0.001));
    });

    test('sin cambios anteriores al mes no hay variación', () {
      final nueva = FichaPrecio(
        precio: actual(4600),
        historial: [registro(4600, DateTime(2026, 11, 10))],
      );
      expect(nueva.variacionDelMes(ahora), isNull);
      expect(nueva.variacionUltimoCambio(), isNull);
    });

    test('la gráfica arranca con el precio vigente hace 4 meses', () {
      final puntos = puntosDeHistorial(ficha, ahora);

      expect(puntos.first.fecha, DateTime(2026, 8));
      expect(puntos.first.precio, 4200);
      expect([for (final p in puntos) p.precio], [4200, 5000, 4600, 4600]);
      expect(puntos.last.fecha, ahora);
    });

    test('sin precio no hay puntos', () {
      expect(puntosDeHistorial(const FichaPrecio(), ahora), isEmpty);
    });
  });
}
