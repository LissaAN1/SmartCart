import 'package:smartcart/features/reportes/domain/entities/reporte.dart';

/// De dónde sale la foto de la etiqueta.
enum OrigenFoto {
  /// Tomarla en el momento con la cámara.
  camara,

  /// Subir una que ya está en el dispositivo.
  galeria,
}

/// Contrato para obtener la foto de la etiqueta. El dominio no sabe cómo se
/// abre la cámara ni la galería: lo resuelve la capa de datos.
abstract class SelectorFoto {
  /// Si se ofrece "Tomar foto" con la cámara (Android, iOS y web). En las
  /// apps de escritorio solo se puede subir una imagen.
  bool get hayCamara;

  /// La foto elegida, o `null` si la persona canceló. Con [OrigenFoto.camara]
  /// en un dispositivo sin cámara se abre la galería. Lanza `AuthFailure` si
  /// no se dio el permiso de la cámara.
  Future<FotoReporte?> elegir(OrigenFoto origen);
}
