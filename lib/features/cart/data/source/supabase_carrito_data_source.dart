import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/catalog/data/source/producto_con_comercio_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe el carrito en Supabase: la función
/// `mi_carrito` para leerlo, `agregar_al_carrito` para sumar productos y la
/// tabla `carrito_item` para cambiar cantidades y quitar líneas. Las políticas
/// RLS (docs/sql/sprint2_hu17.sql) hacen que cada cliente solo vea y toque el
/// suyo.
class SupabaseCarritoDataSource {
  final SupabaseClient _client;

  SupabaseCarritoDataSource({required SupabaseClient client})
      : _client = client;

  Future<List<ItemCarrito>> obtener() {
    return traducirErroresSupabase(() async {
      final rows =
          await _client.rpc(SupabaseFunctions.miCarrito) as List<dynamic>;
      return [
        for (final row in rows)
          ItemCarrito(
            producto: productoConComercioFromRow(row as Map<String, dynamic>),
            cantidad: (row[SupabaseColumns.filaCantidad] as num).toInt(),
          ),
      ];
    });
  }

  Future<int> agregar(String idProducto) {
    return traducirErroresSupabase(() async {
      final cantidad = await _client.rpc(
        SupabaseFunctions.agregarAlCarrito,
        params: {'p_id_producto': idProducto, 'p_cantidad': 1},
      );
      return (cantidad as num).toInt();
    });
  }

  Future<void> cambiarCantidad(String idProducto, int cantidad) {
    return traducirErroresSupabase(() async {
      final filas = await _client
          .from(SupabaseTables.carritoItem)
          .update({SupabaseColumns.carritoCantidad: cantidad})
          .eq(SupabaseColumns.carritoProducto, idProducto)
          .select(SupabaseColumns.carritoProducto);
      // La política RLS solo deja ver las líneas propias: sin filas, esa
      // línea ya no existe (por ejemplo se quitó desde otro dispositivo).
      if (filas.isEmpty) {
        throw const AuthFailure('Ese producto ya no está en tu carrito.');
      }
    });
  }

  Future<void> quitar(String idProducto) {
    return traducirErroresSupabase(() async {
      await _client
          .from(SupabaseTables.carritoItem)
          .delete()
          .eq(SupabaseColumns.carritoProducto, idProducto);
    });
  }
}
