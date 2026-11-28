import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';

/// El precio de una línea del carrito tal como está (HU-18, primer criterio
/// de aceptación).
class PrecioLinea {
  /// Precio vigente por unidad (el de la promoción si está vigente);
  /// `null` si el producto no tiene precio o está agotado.
  final int? precio;
  final bool enPromocion;
  final bool agotado;

  const PrecioLinea({this.precio, this.enPromocion = false, this.agotado = false});

  static PrecioLinea de(OfertaComparable? oferta) => oferta == null
      ? const PrecioLinea()
      : PrecioLinea(
          precio: oferta.disponible ? oferta.precio : null,
          enPromocion: oferta.disponible && oferta.enPromocion,
          agotado: !oferta.disponible,
        );

  int? subtotal(int cantidad) => precio == null ? null : precio! * cantidad;
}

/// El total del carrito en pesos y cuántos productos no se pudieron sumar
/// porque no tienen precio o están agotados.
class ValorCarrito {
  final int total;
  final int sinPrecio;

  const ValorCarrito({required this.total, required this.sinPrecio});

  /// Usa las cantidades de [items] (las que ve el cliente ahora) y el precio
  /// de cada producto en [precios].
  static ValorCarrito de(
    List<ItemCarrito> items,
    Map<String, PrecioLinea> precios,
  ) {
    var total = 0;
    var sinPrecio = 0;
    for (final item in items) {
      final subtotal = precios[item.idProducto]?.subtotal(item.cantidad);
      if (subtotal == null) {
        sinPrecio++;
      } else {
        total += subtotal;
      }
    }
    return ValorCarrito(total: total, sinPrecio: sinPrecio);
  }
}
