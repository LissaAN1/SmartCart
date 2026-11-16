import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_imagen.dart';

/// HU-11: abre el selector para elegir la foto de un producto. No la sube:
/// se sube al guardar.
class ElegirFotoProductoUseCase {
  /// Tope del archivo: 5 MB.
  static const tamanoMaximo = 5 * 1024 * 1024;

  final SelectorImagen _selector;

  ElegirFotoProductoUseCase({required SelectorImagen selector})
      : _selector = selector;

  /// La foto elegida, o `null` si la persona canceló.
  Future<ImagenProducto?> call() async {
    final foto = await _selector.elegir();
    if (foto != null && foto.bytes.length > tamanoMaximo) {
      throw const AuthFailure('La foto pesa más de 5 MB. Elige una más liviana.');
    }
    return foto;
  }
}
