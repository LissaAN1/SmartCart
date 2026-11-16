import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/utils/json_helpers.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que llama a `buscar_productos` y `precios_de_producto`
/// (HU-12, docs/sql/sprint2_hu12.sql). El cliente no lee las tablas: esas
/// funciones solo devuelven productos con precio de comercios aprobados.
class SupabaseBusquedaDataSource {
  final SupabaseClient _client;

  SupabaseBusquedaDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<ResultadoBusqueda>> buscar(
    String texto,
    PageRequest request,
  ) {
    return _proteger(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.buscarProductos,
        params: {
          'p_texto': texto,
          // Una fila de más indica que hay otra página (PagedResult).
          'p_limite': request.pageSize + 1,
          'p_desde': request.from,
        },
      );
      return PagedResult.fromRows(
        [for (final row in _filas(rows)) _toResultado(row)],
        request,
      );
    });
  }

  Future<DetalleProducto?> detalle(String clave) {
    return _proteger(() async {
      final rows = _filas(await _client.rpc(
        SupabaseFunctions.preciosDeProducto,
        params: {'p_clave': clave},
      ));
      if (rows.isEmpty) return null;
      final primera = rows.first;
      return DetalleProducto(
        clave: clave,
        nombre: primera[SupabaseColumns.busquedaNombre] as String? ?? '',
        marca: primera[SupabaseColumns.busquedaMarca] as String?,
        codigoBarras: primera[SupabaseColumns.busquedaCodigo] as String?,
        categoria: primera[SupabaseColumns.busquedaCategoria] as String? ?? '',
        fotoUrl: _primeraFoto(rows),
        ofertas: [for (final row in rows) _toOferta(row)],
      );
    });
  }

  static List<Map<String, dynamic>> _filas(dynamic rows) => [
        if (rows is List)
          for (final row in rows)
            if (row is Map) Map<String, dynamic>.from(row),
      ];

  /// Varios comercios pueden tener foto del mismo producto: se usa la
  /// primera que haya.
  static String? _primeraFoto(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final foto = row[SupabaseColumns.busquedaFoto] as String?;
      if (foto != null && foto.isNotEmpty) return foto;
    }
    return null;
  }

  /// Traduce los errores del SDK a [AuthFailure], igual que el catálogo.
  Future<T> _proteger<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  ResultadoBusqueda _toResultado(Map<String, dynamic> row) => ResultadoBusqueda(
        clave: row[SupabaseColumns.busquedaClave].toString(),
        nombre: row[SupabaseColumns.busquedaNombre] as String? ?? '',
        marca: row[SupabaseColumns.busquedaMarca] as String?,
        codigoBarras: row[SupabaseColumns.busquedaCodigo] as String?,
        categoria: row[SupabaseColumns.busquedaCategoria] as String? ?? '',
        fotoUrl: row[SupabaseColumns.busquedaFoto] as String?,
        precioMin: parseInt(row[SupabaseColumns.busquedaPrecioMin]),
        precioMax: parseInt(row[SupabaseColumns.busquedaPrecioMax]),
        establecimientos:
            parseInt(row[SupabaseColumns.busquedaEstablecimientos]) ?? 0,
      );

  OfertaProducto _toOferta(Map<String, dynamic> row) => OfertaProducto(
        idProducto: row[SupabaseColumns.ofertaProducto].toString(),
        comercio: row[SupabaseColumns.ofertaComercio] as String? ?? '',
        direccion: row[SupabaseColumns.ofertaDireccion] as String?,
        ciudad: row[SupabaseColumns.ofertaCiudad] as String?,
        precio: parseInt(row[SupabaseColumns.ofertaPrecio]) ?? 0,
        precioNormal: parseInt(row[SupabaseColumns.ofertaPrecioNormal]) ?? 0,
        enPromocion: parseBool(row[SupabaseColumns.ofertaEnPromocion]),
        disponible: parseBool(row[SupabaseColumns.ofertaDisponible]),
        fuente: FuentePrecio.desdeCodigo(
            row[SupabaseColumns.ofertaFuente] as String?),
        actualizadoEn: parseDate(row[SupabaseColumns.ofertaActualizadoEn]) ??
            DateTime.now(),
      );
}
