import 'package:smartcart/features/catalog/domain/entities/producto_con_comercio.dart';

/// Una línea del carrito: un producto y cuántas unidades se quieren. El
/// carrito guarda una sola línea por producto.
class ItemCarrito {
  final ProductoConComercio producto;
  final int cantidad;

  const ItemCarrito({required this.producto, required this.cantidad});

  String get idProducto => producto.id;

  ItemCarrito conCantidad(int nueva) =>
      ItemCarrito(producto: producto, cantidad: nueva);
}

/// Cuántos productos y cuántas unidades hay en una lista de líneas.
extension ResumenCarrito on List<ItemCarrito> {
  /// Cantidad de productos distintos (líneas). Es el número del carrito.
  int get productos => length;

  /// Suma de las cantidades de todas las líneas.
  int get unidades => fold(0, (suma, item) => suma + item.cantidad);
}
