import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';

/// Contrato del carrito del cliente. Se guarda en la base: por eso se
/// recupera al volver a abrir la app.
abstract class CarritoRepository {
  /// Las líneas del carrito, de la modificada más recientemente a la más
  /// antigua.
  Future<List<ItemCarrito>> obtener();

  /// Agrega un producto con cantidad 1; si ya estaba, le suma 1. Devuelve la
  /// cantidad que queda.
  Future<int> agregar(String idProducto);

  /// Deja la línea de [idProducto] con [cantidad] unidades.
  Future<void> cambiarCantidad(String idProducto, int cantidad);

  /// Quita la línea de [idProducto].
  Future<void> quitar(String idProducto);
}
