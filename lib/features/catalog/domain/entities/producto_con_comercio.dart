import 'package:smartcart/features/catalog/domain/entities/producto.dart';

/// Un producto junto con el comercio que lo vende. Es lo que ve el cliente en
/// el carrito, en los favoritos y al explorar: la HU-10 solo mostraba los
/// productos al dueño, que ya sabe de qué comercio son.
class ProductoConComercio {
  final Producto producto;
  final String idComercio;

  /// Nombre del comercio.
  final String comercio;

  const ProductoConComercio({
    required this.producto,
    required this.idComercio,
    required this.comercio,
  });

  String get id => producto.id;
}
