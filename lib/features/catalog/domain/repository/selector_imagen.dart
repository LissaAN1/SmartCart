import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';

/// Contrato para que la persona elija una foto del dispositivo (HU-11). El
/// dominio no sabe cómo se abre el selector: lo resuelve la capa de datos.
abstract class SelectorImagen {
  /// La foto elegida, o `null` si la persona canceló.
  Future<ImagenProducto?> elegir();
}
