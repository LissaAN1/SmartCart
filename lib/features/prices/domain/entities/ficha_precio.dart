import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';

/// Todo lo de precios de un producto: el precio actual (si ya tiene), la
/// promoción (si hay) y los últimos cambios.
class FichaPrecio {
  final PrecioProducto? precio;
  final Promocion? promocion;
  final List<RegistroPrecio> historial;

  const FichaPrecio({
    this.precio,
    this.promocion,
    this.historial = const [],
  });

  /// La promoción solo si está vigente hoy.
  Promocion? promocionVigente(DateTime ahora) {
    final promo = promocion;
    return promo != null && promo.vigenteEn(ahora) ? promo : null;
  }

  /// El precio que vería un cliente: el promocional si la promoción está
  /// vigente; si no, el normal (escenario 3). `null` si aún no tiene precio.
  int? precioMostrado(DateTime ahora) {
    final normal = precio;
    if (normal == null) return null;
    return promocionVigente(ahora)?.precioPromocional ?? normal.precio;
  }

  FichaPrecio copyWith({
    PrecioProducto? precio,
    Promocion? promocion,
    bool sinPromocion = false,
    List<RegistroPrecio>? historial,
  }) {
    return FichaPrecio(
      precio: precio ?? this.precio,
      promocion: sinPromocion ? null : promocion ?? this.promocion,
      historial: historial ?? this.historial,
    );
  }
}
