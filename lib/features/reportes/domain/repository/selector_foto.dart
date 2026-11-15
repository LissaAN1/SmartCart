import 'package:smartcart/features/reportes/domain/entities/reporte.dart';

/// Contrato para tomar la foto de la etiqueta. El dominio no sabe si sale de
/// la cámara o de la galería: lo resuelve la capa de datos.
abstract class SelectorFoto {
  /// La foto tomada, o `null` si la persona canceló. Lanza `AuthFailure` si
  /// no se dio el permiso de la cámara.
  Future<FotoReporte?> tomar();
}
