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

  /// Porcentaje de cambio entre el precio actual y el anterior del
  /// historial ("-5 %"). `null` si todavía no hubo un cambio de precio.
  double? variacionUltimoCambio() {
    final actual = precio;
    if (actual == null) return null;
    for (final registro in historial) {
      if (registro.precio != actual.precio) {
        return _porcentaje(registro.precio, actual.precio);
      }
    }
    return null;
  }

  /// Porcentaje de cambio del precio en el mes de [ahora]: compara el precio
  /// actual con el que regía al empezar el mes. `null` si no hay registro
  /// anterior al mes.
  double? variacionDelMes(DateTime ahora) {
    final actual = precio;
    if (actual == null) return null;
    final inicioMes = DateTime(ahora.year, ahora.month);
    // El historial viene del más reciente al más antiguo.
    for (final registro in historial) {
      if (registro.registradoEn.isBefore(inicioMes)) {
        return _porcentaje(registro.precio, actual.precio);
      }
    }
    return null;
  }

  static double _porcentaje(int antes, int despues) =>
      (despues - antes) / antes * 100;

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
