import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe las tablas `producto` y `categoria`.
/// Solo el dueño de un comercio aprobado ve y modifica los productos de ese
/// comercio (políticas RLS de docs/sql/sprint2_hu10.sql); aquí además se
/// filtra siempre por el id del comercio.
class SupabaseCatalogoDataSource {
  /// Trae la categoría junto con el producto en una sola consulta.
  static const _seleccion =
      '*, ${SupabaseTables.categoria}(${SupabaseColumns.categoriaId}, '
      '${SupabaseColumns.categoriaNombre})';

  /// Tamaño de cada lote al enviar varios productos o consultar varios
  /// códigos: evita pedidos demasiado grandes.
  static const _lote = 100;

  final SupabaseClient _client;

  SupabaseCatalogoDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<Producto>> productos(
    String idComercio,
    PageRequest request,
  ) {
    return _proteger(() async {
      final rows = await _client
          .from(SupabaseTables.producto)
          .select(_seleccion)
          .eq(SupabaseColumns.productoComercio, idComercio)
          .order(SupabaseColumns.productoCreadoEn, ascending: false)
          .order(SupabaseColumns.productoId, ascending: true)
          .range(request.from, request.to);
      return PagedResult.fromRows(
        [for (final row in rows) _toProducto(row)],
        request,
      );
    });
  }

  Future<List<Categoria>> categorias() {
    return _proteger(() async {
      final rows = await _client
          .from(SupabaseTables.categoria)
          .select()
          .order(SupabaseColumns.categoriaNombre, ascending: true);
      return [
        for (final row in rows)
          Categoria(
            id: row[SupabaseColumns.categoriaId].toString(),
            nombre: row[SupabaseColumns.categoriaNombre] as String? ?? '',
          ),
      ];
    });
  }

  Future<Producto> crear(String idComercio, ProductoDatos datos) {
    return _proteger(() async {
      final row = await _client
          .from(SupabaseTables.producto)
          .insert(_toRow(idComercio, datos))
          .select(_seleccion)
          .single();
      return _toProducto(row);
    });
  }

  Future<Producto> editar(String idProducto, ProductoDatos datos) {
    return _proteger(() async {
      final row = await _client
          .from(SupabaseTables.producto)
          .update(_toRow(null, datos))
          .eq(SupabaseColumns.productoId, idProducto)
          .select(_seleccion)
          .maybeSingle();
      // Si la política RLS no deja ver la fila (no es de este comercio),
      // el update no toca nada y no hay fila que devolver.
      if (row == null) throw const AuthFailure('No encontramos ese producto.');
      return _toProducto(row);
    });
  }

  Future<void> eliminar(String idProducto) {
    return _proteger(() async {
      final rows = await _client
          .from(SupabaseTables.producto)
          .delete()
          .eq(SupabaseColumns.productoId, idProducto)
          .select(SupabaseColumns.productoId);
      if (rows.isEmpty) throw const AuthFailure('No encontramos ese producto.');
    });
  }

  Future<Set<String>> codigosExistentes(
    String idComercio,
    List<String> codigos,
  ) {
    return _proteger(() async {
      final existentes = <String>{};
      for (var i = 0; i < codigos.length; i += _lote) {
        final lote = codigos.sublist(
          i,
          i + _lote > codigos.length ? codigos.length : i + _lote,
        );
        final rows = await _client
            .from(SupabaseTables.producto)
            .select(SupabaseColumns.productoCodigoBarras)
            .eq(SupabaseColumns.productoComercio, idComercio)
            .inFilter(SupabaseColumns.productoCodigoBarras, lote);
        for (final row in rows) {
          existentes.add(row[SupabaseColumns.productoCodigoBarras] as String);
        }
      }
      return existentes;
    });
  }

  Future<void> crearVarios(String idComercio, List<ProductoDatos> productos) {
    return _proteger(() async {
      for (var i = 0; i < productos.length; i += _lote) {
        final lote = productos.sublist(
          i,
          i + _lote > productos.length ? productos.length : i + _lote,
        );
        await _client.from(SupabaseTables.producto).insert([
          for (final datos in lote) _toRow(idComercio, datos),
        ]);
      }
    });
  }

  /// Traduce los errores del SDK a [AuthFailure] para que ni los casos de uso
  /// ni la interfaz conozcan Supabase.
  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      // 23505: el índice único (comercio, código de barras).
      if (e.code == '23505') {
        throw const AuthFailure(
          'Ya tienes un producto con ese código de barras.',
        );
      }
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Map<String, dynamic> _toRow(String? idComercio, ProductoDatos datos) => {
        if (idComercio != null) SupabaseColumns.productoComercio: idComercio,
        SupabaseColumns.productoNombre: datos.nombre,
        SupabaseColumns.productoMarca: datos.marca,
        SupabaseColumns.productoCodigoBarras: datos.codigoBarras,
        SupabaseColumns.productoCategoria: datos.idCategoria,
      };

  Producto _toProducto(Map<String, dynamic> row) {
    final categoria = row[SupabaseTables.categoria];
    return Producto(
      id: row[SupabaseColumns.productoId].toString(),
      nombre: row[SupabaseColumns.productoNombre] as String? ?? '',
      marca: row[SupabaseColumns.productoMarca] as String?,
      codigoBarras: row[SupabaseColumns.productoCodigoBarras] as String?,
      idCategoria: row[SupabaseColumns.productoCategoria].toString(),
      categoria: categoria is Map
          ? categoria[SupabaseColumns.categoriaNombre] as String? ?? ''
          : '',
    );
  }
}
