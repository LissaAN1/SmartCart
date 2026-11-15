import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';

import '../support/fakes.dart';

const _arroz = ProductoDatos(
  nombre: 'Arroz blanco 500 g',
  codigoBarras: '7701234567890',
  idCategoria: 'cat-super',
);

Future<ProductoFormState> _hasta(
  ProductoFormBloc bloc,
  ProductoFormStatus status,
) =>
    bloc.stream.firstWhere((s) => s.status == status);

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv()..iniciarSesionComoComercio(ApprovalStatus.aprobado);
  });

  group('ProductoFormBloc', () {
    test('al iniciar carga las categorías', () async {
      final bloc = env.productoFormBloc();

      bloc.add(ProductoFormStarted());
      final state = await _hasta(bloc, ProductoFormStatus.ready);

      expect(state.categorias.map((c) => c.nombre), ['Super', 'Frutas', 'Lácteos']);
      await bloc.close();
    });

    test('si las categorías no cargan deja el error y permite reintentar',
        () async {
      env.catalogo.categoriasError = const AuthFailure('Sin conexión.');
      final bloc = env.productoFormBloc();

      bloc.add(ProductoFormStarted());
      final fallo = await _hasta(bloc, ProductoFormStatus.categoriasFailed);
      expect(fallo.errorMessage, 'Sin conexión.');

      env.catalogo.categoriasError = null;
      bloc.add(ProductoFormStarted());
      final listo = await _hasta(bloc, ProductoFormStatus.ready);
      expect(listo.errorMessage, isNull);
      await bloc.close();
    });

    test('guardar un producto nuevo lo crea y queda en saved', () async {
      final bloc = env.productoFormBloc();
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormGuardado(_arroz));
      final state = await _hasta(bloc, ProductoFormStatus.saved);

      expect(env.catalogo.creados.single.datos.nombre, 'Arroz blanco 500 g');
      // Las categorías siguen disponibles después de guardar.
      expect(state.categorias, isNotEmpty);
      await bloc.close();
    });

    test('un segundo toque mientras guarda no crea el producto dos veces',
        () async {
      final bloc = env.productoFormBloc();
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc
        ..add(ProductoFormGuardado(_arroz))
        ..add(ProductoFormGuardado(_arroz));
      await _hasta(bloc, ProductoFormStatus.saved);

      expect(env.catalogo.creados.length, 1);
      await bloc.close();
    });

    test('si guardar falla muestra el mensaje y conserva las categorías',
        () async {
      env.catalogo.crearError = const AuthFailure('No pudimos guardar.');
      final bloc = env.productoFormBloc();
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormGuardado(_arroz));
      final state = await _hasta(bloc, ProductoFormStatus.saveFailed);

      expect(state.errorMessage, 'No pudimos guardar.');
      expect(state.categorias, isNotEmpty);
      await bloc.close();
    });

    test('un error que no es esperado se muestra con un mensaje genérico',
        () async {
      env.catalogo.crearError = StateError('boom');
      final bloc = env.productoFormBloc();
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormGuardado(_arroz));
      final state = await _hasta(bloc, ProductoFormStatus.saveFailed);

      expect(state.errorMessage, contains('error inesperado'));
      await bloc.close();
    });

    test('al editar actualiza el producto existente en vez de crear otro',
        () async {
      final existente = await env.crearProducto(_arroz);
      final bloc = env.productoFormBloc(editando: existente);
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormGuardado(const ProductoDatos(
        nombre: 'Arroz integral',
        idCategoria: 'cat-super',
      )));
      await _hasta(bloc, ProductoFormStatus.saved);

      expect(env.catalogo.deComercio('c1').single.nombre, 'Arroz integral');
      expect(env.catalogo.creados.length, 1);
      await bloc.close();
    });

    test('eliminar quita el producto y queda en deleted', () async {
      final existente = await env.crearProducto(_arroz);
      final bloc = env.productoFormBloc(editando: existente);
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormEliminado());
      await _hasta(bloc, ProductoFormStatus.deleted);

      expect(env.catalogo.deComercio('c1'), isEmpty);
      await bloc.close();
    });

    test('eliminar sin un producto en edición no hace nada', () async {
      final bloc = env.productoFormBloc();
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormEliminado());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, ProductoFormStatus.ready);
      await bloc.close();
    });

    test('si eliminar falla deja el error', () async {
      final existente = await env.crearProducto(_arroz);
      env.catalogo.eliminarError = const AuthFailure('No se pudo eliminar.');
      final bloc = env.productoFormBloc(editando: existente);
      bloc.add(ProductoFormStarted());
      await _hasta(bloc, ProductoFormStatus.ready);

      bloc.add(ProductoFormEliminado());
      final state = await _hasta(bloc, ProductoFormStatus.saveFailed);

      expect(state.errorMessage, 'No se pudo eliminar.');
      expect(env.catalogo.deComercio('c1').length, 1);
      await bloc.close();
    });
  });

  group('PaginatedBloc<Producto> (lista del catálogo)', () {
    test('carga la primera página y luego la siguiente', () async {
      env.catalogo.precargar('c1', 5);
      final bloc = env.productosBloc(pageSize: 3);

      bloc.add(PaginatedStarted());
      var state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.success);
      expect(state.items.length, 3);
      expect(state.hasMore, isTrue);

      bloc.add(NextPageRequested());
      state = await bloc.stream.firstWhere((s) => s.items.length == 5);
      expect(state.hasMore, isFalse);
      await bloc.close();
    });

    test('un comercio pendiente recibe el aviso de espera', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);
      final bloc = env.productosBloc();

      bloc.add(PaginatedStarted());
      final state = await bloc.stream
          .firstWhere((s) => s.status == PaginatedStatus.failure);

      expect(state.errorMessage, contains('pendiente de aprobación'));
      await bloc.close();
    });
  });

  group('CargaCsvBloc', () {
    const archivo = ArchivoCsv(
      nombre: 'productos.csv',
      contenido: 'nombre,categoria\nArroz blanco,Super\nab,Super\n',
    );

    Future<CargaCsvState> hasta(CargaCsvBloc bloc, CargaCsvStatus status) =>
        bloc.stream.firstWhere((s) => s.status == status);

    test('elegir un archivo carga las filas válidas y deja el resultado',
        () async {
      env.selectorCsv.archivo = archivo;
      final bloc = env.cargaCsvBloc();

      bloc.add(CargaCsvArchivoSolicitado());
      final state = await hasta(bloc, CargaCsvStatus.listo);

      expect(state.archivo, 'productos.csv');
      expect(state.resultado!.cargados, 1);
      expect(state.resultado!.errores.single.fila, 3);
      expect(env.catalogo.deComercio('c1').single.nombre, 'Arroz blanco');
      await bloc.close();
    });

    test('cancelar el selector no cambia nada ni es un error', () async {
      env.selectorCsv.archivo = null;
      final bloc = env.cargaCsvBloc();

      bloc.add(CargaCsvArchivoSolicitado());
      await hasta(bloc, CargaCsvStatus.initial);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, CargaCsvStatus.initial);
      expect(env.catalogo.crearVariosCalls, 0);
      await bloc.close();
    });

    test('un archivo con formato inválido deja el error', () async {
      env.selectorCsv.archivo =
          const ArchivoCsv(nombre: 'malo.csv', contenido: 'marca\nDiana\n');
      final bloc = env.cargaCsvBloc();

      bloc.add(CargaCsvArchivoSolicitado());
      final state = await hasta(bloc, CargaCsvStatus.failed);

      expect(state.errorMessage, contains('"nombre" y "categoria"'));
      await bloc.close();
    });

    test('si no se puede leer el archivo muestra ese error', () async {
      env.selectorCsv.error = const AuthFailure('No pudimos leer el archivo.');
      final bloc = env.cargaCsvBloc();

      bloc.add(CargaCsvArchivoSolicitado());
      final state = await hasta(bloc, CargaCsvStatus.failed);

      expect(state.errorMessage, 'No pudimos leer el archivo.');
      await bloc.close();
    });

    test('un comercio pendiente no puede cargar archivos', () async {
      env.iniciarSesionComoComercio(ApprovalStatus.pendiente);
      env.selectorCsv.archivo = archivo;
      final bloc = env.cargaCsvBloc();

      bloc.add(CargaCsvArchivoSolicitado());
      final state = await hasta(bloc, CargaCsvStatus.failed);

      expect(state.errorMessage, contains('pendiente'));
      expect(env.catalogo.creados, isEmpty);
      await bloc.close();
    });

    test('mientras carga ignora otro toque en el botón', () async {
      env.selectorCsv.archivo = archivo;
      final bloc = env.cargaCsvBloc();

      bloc
        ..add(CargaCsvArchivoSolicitado())
        ..add(CargaCsvArchivoSolicitado());
      await hasta(bloc, CargaCsvStatus.listo);

      expect(env.selectorCsv.llamadas, 1);
      await bloc.close();
    });
  });
}
