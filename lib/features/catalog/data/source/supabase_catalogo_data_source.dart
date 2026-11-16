import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/utils/json_helpers.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe las tablas `producto` y `categoria`.
/// Solo el dueño de un comercio aprobado ve y modifica los productos de ese
/// comercio (políticas RLS de docs/sql/sprint2_hu10.sql); aquí además se
/// filtra siempre por el id del comercio.
class SupabaseCatalogoDataSource {
  /// Trae la categoría y el precio actual (HU-11) junto con el producto en
  /// una sola consulta.
  static const _seleccion =
      '*, ${SupabaseTables.categoria}(${SupabaseColumns.categoriaId}, '
      '${SupabaseColumns.categoriaNombre}), '
      '${SupabaseTables.precioProducto}(${SupabaseColumns.precioValor}, '
      '${SupabaseColumns.precioDisponible})';

  /// Tamaño de cada lote al enviar varios productos o consultar varios
  /// códigos: evita pedidos demasiado grandes.
  static const _lote = 100;

  final SupabaseClient _client;

  SupabaseCatalogoDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<Producto>> productos(
    String idComercio,
    PageRequest request, {
    FiltroCatalogo filtro = const FiltroCatalogo(),
  }) {
    return _proteger(() async {
      var query = _client
          .from(SupabaseTables.producto)
          .select(_seleccion)
          .eq(SupabaseColumns.productoComercio, idComercio);
      final idCategoria = filtro.idCategoria;
      if (idCategoria != null) {
        query = query.eq(SupabaseColumns.productoCategoria, idCategoria);
      }
      final texto = textoBuscable(filtro.texto);
      if (texto.isNotEmpty) {
        query = query.or(
          '${SupabaseColumns.productoNombre}.ilike.%$texto%,'
          '${SupabaseColumns.productoMarca}.ilike.%$texto%',
        );
      }
      final rows = await query
          .order(SupabaseColumns.productoCreadoEn, ascending: false)
          .order(SupabaseColumns.productoId, ascending: true)
          .range(request.from, request.to);
      return PagedResult.fromRows(
        [for (final row in rows) _toProducto(row)],
        request,
      );
    });
  }

  /// HU-11: lo calcula la base (`resumen_catalogo`), así incluye los
  /// productos de todas las páginas.
  Future<ResumenCatalogo> resumen(String idComercio) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.resumenCatalogo,
        params: {'p_id_comercio': idComercio},
      );
      final fila = rows is List && rows.isNotEmpty ? rows.first : rows;
      if (fila is! Map) return const ResumenCatalogo();
      return ResumenCatalogo(
        totalProductos: parseInt(fila[SupabaseColumns.resumenTotal]) ?? 0,
        valorStock: parseInt(fila[SupabaseColumns.resumenValorStock]) ?? 0,
        bajoStock: parseInt(fila[SupabaseColumns.resumenBajoStock]) ?? 0,
      );
    });
  }

  /// HU-11: sube la foto a `productos/<id_comercio>/` (la política de Storage
  /// solo deja escribir en la carpeta del comercio propio) y guarda su URL
  /// pública en el producto. Un nombre nuevo cada vez evita que el teléfono
  /// muestre la foto anterior guardada en caché.
  Future<Producto> subirFoto(
    String idComercio,
    Producto producto,
    ImagenProducto foto,
  ) {
    return _proteger(() async {
      final ruta = '$idComercio/${producto.id}-'
          '${DateTime.now().millisecondsSinceEpoch}.${foto.extension}';
      final bucket = _client.storage.from(SupabaseBuckets.productos);
      try {
        await bucket.uploadBinary(
          ruta,
          foto.bytes,
          fileOptions: FileOptions(contentType: foto.contentType),
        );
      } on StorageException {
        throw const AuthFailure(
          'No pudimos subir la foto. Revisa tu conexión e inténtalo de nuevo.',
        );
      }
      final url = bucket.getPublicUrl(ruta);
      final row = await _client
          .from(SupabaseTables.producto)
          .update({SupabaseColumns.productoFotoUrl: url})
          .eq(SupabaseColumns.productoId, producto.id)
          .select(_seleccion)
          .maybeSingle();
      if (row == null) throw const AuthFailure('No encontramos ese producto.');
      return _toProducto(row);
    });
  }

  /// Quita del texto buscado los caracteres que tienen significado en el
  /// filtro `or` de PostgREST (coma, paréntesis) y los comodines de `ilike`.
  static String textoBuscable(String texto) =>
      texto.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();

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
        SupabaseColumns.productoStock: datos.stock,
      };

  Producto _toProducto(Map<String, dynamic> row) {
    final categoria = row[SupabaseTables.categoria];
    // precio_producto es 1 a 1 con producto: llega como objeto, o como
    // lista según cómo PostgREST lea la relación.
    final embebido = row[SupabaseTables.precioProducto];
    final precio = embebido is List
        ? (embebido.isEmpty ? null : embebido.first)
        : embebido;
    return Producto(
      id: row[SupabaseColumns.productoId].toString(),
      nombre: row[SupabaseColumns.productoNombre] as String? ?? '',
      marca: row[SupabaseColumns.productoMarca] as String?,
      codigoBarras: row[SupabaseColumns.productoCodigoBarras] as String?,
      idCategoria: row[SupabaseColumns.productoCategoria].toString(),
      categoria: categoria is Map
          ? categoria[SupabaseColumns.categoriaNombre] as String? ?? ''
          : '',
      precio: precio is Map ? parseInt(precio[SupabaseColumns.precioValor]) : null,
      disponible: precio is Map
          ? parseBool(precio[SupabaseColumns.precioDisponible])
          : true,
      stock: parseInt(row[SupabaseColumns.productoStock]) ?? 0,
      fotoUrl: row[SupabaseColumns.productoFotoUrl] as String?,
    );
  }
}
