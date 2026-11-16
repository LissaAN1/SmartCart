import 'dart:typed_data';

/// Foto que la persona eligió para un producto, todavía sin subir.
class ImagenProducto {
  final Uint8List bytes;

  /// "jpg", "png" o "webp", en minúscula.
  final String extension;

  const ImagenProducto({required this.bytes, required this.extension});

  /// Tipo MIME para Supabase Storage.
  String get contentType => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
