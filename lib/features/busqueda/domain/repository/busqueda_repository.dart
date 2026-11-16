import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/entities/resultado_busqueda.dart';

/// Contrato de la búsqueda de productos del cliente (HU-12).
abstract class BusquedaRepository {
  /// Una página de productos cuyo nombre o marca contiene [texto].
  Future<PagedResult<ResultadoBusqueda>> buscar(
    String texto,
    PageRequest request,
  );

  /// El producto con el precio de cada establecimiento, o `null` si no hay
  /// ninguna oferta publicada con esa [clave].
  Future<DetalleProducto?> detalle(String clave);
}
