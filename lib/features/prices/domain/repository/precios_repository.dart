import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';

/// Contrato de los precios, la disponibilidad y las promociones de los
/// productos de un comercio (HU-11).
abstract class PreciosRepository {
  /// Precio actual del producto, o `null` si todavía no tiene.
  Future<PrecioProducto?> precio(String idProducto);

  /// Promoción del producto, o `null` si no tiene.
  Future<Promocion?> promocion(String idProducto);

  /// Los cambios más recientes primero.
  Future<List<RegistroPrecio>> historial(String idProducto, {int limite = 10});

  /// Crea o actualiza el precio actual. La base fija la fecha y la fuente
  /// "comercio", y escribe el historial.
  Future<PrecioProducto> guardarPrecio(String idProducto, PrecioDatos datos);

  /// Crea la promoción o reemplaza la que había.
  Future<Promocion> guardarPromocion(String idProducto, PromocionDatos datos);

  Future<void> quitarPromocion(String idProducto);
}
