import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Contrato para conocer dónde está la persona. El dominio no sabe si viene
/// del GPS, de una red o de una prueba: lo resuelve la capa de datos.
abstract class ServicioUbicacion {
  /// La ubicación actual. Lanza `AuthFailure` con un mensaje claro si el GPS
  /// está apagado, el permiso fue negado o no se pudo obtener a tiempo.
  Future<Ubicacion> actual();
}
