import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/servicio_ubicacion.dart';

/// Pide la ubicación actual de la persona. La usan el registro del comercio
/// (HU-07) y el reporte de precios (HU-14).
class ObtenerUbicacionUseCase {
  final ServicioUbicacion _servicio;

  ObtenerUbicacionUseCase({required ServicioUbicacion servicio})
      : _servicio = servicio;

  Future<Ubicacion> call() => _servicio.actual();
}
