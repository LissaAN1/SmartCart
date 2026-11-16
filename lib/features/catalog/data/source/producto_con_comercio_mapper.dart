import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';

/// Convierte una fila de las funciones de HU-17 (`mi_carrito`,
/// `mis_favoritos_productos`, `explorar_productos`) en un producto con el
/// nombre de su comercio. A diferencia de `productoFromRow`, aquí la
/// categoría llega como texto y no como una fila anidada.
ProductoConComercio productoConComercioFromRow(Map<String, dynamic> row) {
  return ProductoConComercio(
    producto: Producto(
      id: row[SupabaseColumns.productoId].toString(),
      nombre: row[SupabaseColumns.productoNombre] as String? ?? '',
      marca: row[SupabaseColumns.productoMarca] as String?,
      codigoBarras: row[SupabaseColumns.productoCodigoBarras] as String?,
      idCategoria: row[SupabaseColumns.productoCategoria].toString(),
      categoria: row[SupabaseColumns.filaCategoria] as String? ?? '',
    ),
    idComercio: row[SupabaseColumns.productoComercio].toString(),
    comercio: row[SupabaseColumns.filaComercio] as String? ?? '',
  );
}

/// Convierte una fila de `explorar_comercios` o `mis_favoritos_comercios`.
ComercioResumen comercioResumenFromRow(Map<String, dynamic> row) {
  return ComercioResumen(
    id: row[SupabaseColumns.comercioId].toString(),
    nombre: row[SupabaseColumns.comercioNombre] as String? ?? '',
    direccion: row[SupabaseColumns.comercioDireccion] as String? ?? '',
    ciudad: row[SupabaseColumns.comercioCiudad] as String? ?? '',
  );
}
