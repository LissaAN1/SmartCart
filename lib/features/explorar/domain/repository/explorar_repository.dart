import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';

/// Contrato de la lista mínima que usa el cliente para encontrar productos y
/// comercios y agregarlos al carrito o a favoritos (HU-17). Solo trae
/// comercios aprobados. La búsqueda completa es de la HU-12.
abstract class ExplorarRepository {
  /// Productos cuyo nombre o marca contienen [texto] (todos si está vacío).
  Future<PagedResult<ProductoConComercio>> productos(
    String texto,
    PageRequest request,
  );

  /// Comercios cuyo nombre o ciudad contienen [texto] (todos si está vacío).
  Future<PagedResult<ComercioResumen>> comercios(
    String texto,
    PageRequest request,
  );
}
