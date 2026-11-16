import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/catalog/data/source/producto_con_comercio_mapper.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe los favoritos en Supabase: las tablas
/// `favorito_producto` y `favorito_comercio` para marcar, desmarcar y leer los
/// ids, y las funciones `mis_favoritos_*` para las listas con los nombres.
/// Las políticas RLS hacen que cada cliente solo vea y toque los suyos.
class SupabaseFavoritosDataSource {
  final SupabaseClient _client;

  SupabaseFavoritosDataSource({required SupabaseClient client})
      : _client = client;

  Future<FavoritosIds> ids() {
    return traducirErroresSupabase(() async {
      final productos = await _client
          .from(SupabaseTables.favoritoProducto)
          .select(SupabaseColumns.favoritoProductoId);
      final comercios = await _client
          .from(SupabaseTables.favoritoComercio)
          .select(SupabaseColumns.favoritoComercioId);
      return FavoritosIds(
        productos: {
          for (final row in productos)
            row[SupabaseColumns.favoritoProductoId].toString(),
        },
        comercios: {
          for (final row in comercios)
            row[SupabaseColumns.favoritoComercioId].toString(),
        },
      );
    });
  }

  Future<PagedResult<ProductoConComercio>> productos(PageRequest request) {
    return traducirErroresSupabase(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.misFavoritosProductos,
        params: _pagina(request),
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

  Future<PagedResult<ComercioResumen>> comercios(PageRequest request) {
    return traducirErroresSupabase(() async {
      final rows = await _client.rpc(
        SupabaseFunctions.misFavoritosComercios,
        params: _pagina(request),
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

  Future<void> cambiar(
    TipoFavorito tipo,
    String id, {
    required bool favorito,
  }) {
    final tabla = switch (tipo) {
      TipoFavorito.producto => SupabaseTables.favoritoProducto,
      TipoFavorito.comercio => SupabaseTables.favoritoComercio,
    };
    final columna = switch (tipo) {
      TipoFavorito.producto => SupabaseColumns.favoritoProductoId,
      TipoFavorito.comercio => SupabaseColumns.favoritoComercioId,
    };
    return traducirErroresSupabase(() async {
      if (!favorito) {
        await _client.from(tabla).delete().eq(columna, id);
        return;
      }
      try {
        // `id_usuario` toma por defecto el de la sesión; la política exige
        // que lo sea y que el producto o el comercio estén disponibles.
        await _client.from(tabla).insert({columna: id});
      } on PostgrestException catch (e) {
        // 23505: ya era favorito (por ejemplo, desde otro dispositivo). El
        // resultado que la persona quería ya está, así que no es un error.
        if (e.code != '23505') rethrow;
      }
    });
  }

  /// Una fila de más que el tamaño de página: indica si hay otra página (ver
  /// PageRequest).
  Map<String, dynamic> _pagina(PageRequest request) => {
        'p_limite': request.pageSize + 1,
        'p_desplazamiento': request.from,
      };
}
