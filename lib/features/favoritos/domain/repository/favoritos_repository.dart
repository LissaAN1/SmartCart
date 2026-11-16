import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio_resumen.dart';
import 'package:smartcart/features/favoritos/domain/entities/favoritos.dart';

/// Contrato de los favoritos del cliente: productos y comercios.
abstract class FavoritosRepository {
  /// Los ids de todos los favoritos del cliente.
  Future<FavoritosIds> ids();

  /// Una página de los productos favoritos, del más reciente al más antiguo.
  Future<PagedResult<ProductoConComercio>> productos(PageRequest request);

  /// Una página de los comercios favoritos, del más reciente al más antiguo.
  Future<PagedResult<ComercioResumen>> comercios(PageRequest request);

  /// Marca o desmarca [id] como favorito.
  Future<void> cambiar(TipoFavorito tipo, String id, {required bool favorito});
}
