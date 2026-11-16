import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/catalog/data/source/producto_con_comercio_mapper.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que llama a las funciones `explorar_productos` y
/// `explorar_comercios`. Solo devuelven comercios aprobados y exigen que quien
/// llama sea cliente (docs/sql/sprint2_hu17.sql).
class SupabaseExplorarDataSource {
  final SupabaseClient _client;

  SupabaseExplorarDataSource({required SupabaseClient client})
      : _client = client;

  Future<PagedResult<ProductoConComercio>> productos(
    String texto,
    PageRequest request,
  ) {
    return traducirErroresSupabase(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.explorarProductos,
        params: _parametros(texto, request),
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [
          for (final row in rows)
            productoConComercioFromRow(row as Map<String, dynamic>),
        ],
        request,
      );
    });
  }

  Future<PagedResult<ComercioResumen>> comercios(
    String texto,
    PageRequest request,
  ) {
    return traducirErroresSupabase(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.explorarComercios,
        params: _parametros(texto, request),
      ) as List<dynamic>;
      return PagedResult.fromRows(
        [
          for (final row in rows)
            comercioResumenFromRow(row as Map<String, dynamic>),
        ],
        request,
      );
    });
  }

  /// Una fila de más que el tamaño de página: indica si hay otra página (ver
  /// PageRequest). El texto va como parámetro, no dentro de una consulta: la
  /// función escapa los comodines.
  Map<String, dynamic> _parametros(String texto, PageRequest request) => {
        'p_texto': texto,
        'p_limite': request.pageSize + 1,
        'p_desplazamiento': request.from,
      };
}
