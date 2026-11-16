/// Límites del carrito. Los mismos están en `agregar_al_carrito` y en el
/// `check` de `carrito_item` (docs/sql/sprint2_hu17.sql).
abstract final class CarritoReglas {
  /// Una línea no baja de 1: para sacar un producto se usa "Quitar".
  static const cantidadMin = 1;

  /// Tope de unidades por producto. El backlog no lo define; evita errores
  /// de digitación y cantidades absurdas.
  static const cantidadMax = 99;

  /// Tope de productos distintos. Cargamos el carrito completo en una sola
  /// consulta, así que el límite también la mantiene pequeña.
  static const productosMax = 100;

  static bool cantidadValida(int cantidad) =>
      cantidad >= cantidadMin && cantidad <= cantidadMax;
}
