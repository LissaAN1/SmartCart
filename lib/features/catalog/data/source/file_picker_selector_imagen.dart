import 'package:file_picker/file_picker.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_imagen.dart';

/// Abre la galería o el selector de archivos del sistema para elegir la foto
/// de un producto (HU-11). Igual que el selector del CSV, es la única clase
/// que conoce `file_picker` para esta tarea.
class FilePickerSelectorImagen implements SelectorImagen {
  static const _extensiones = {'jpg', 'jpeg', 'png', 'webp'};

  @override
  Future<ImagenProducto?> elegir() async {
    try {
      final archivo = await FilePicker.pickFile(
        dialogTitle: 'Elige la foto del producto',
        type: FileType.image,
      );
      if (archivo == null) return null;
      final extension = archivo.name.split('.').last.toLowerCase();
      if (!_extensiones.contains(extension)) {
        throw const AuthFailure('Elige una foto JPG, PNG o WEBP.');
      }
      return ImagenProducto(
        bytes: await archivo.readAsBytes(),
        extension: extension == 'jpeg' ? 'jpg' : extension,
      );
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure('No pudimos leer la foto. Inténtalo de nuevo.');
    }
  }
}
