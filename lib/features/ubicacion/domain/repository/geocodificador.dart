import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Convierte una dirección escrita en coordenadas. Sirve cuando el cliente
/// no da el permiso de ubicación (HU-19, escenario 2).
abstract class Geocodificador {
  /// Las coordenadas de [direccion]. Lanza `AuthFailure` con un mensaje claro
  /// si no la encuentra o si el dispositivo no puede buscarla.
  Future<Ubicacion> buscar(String direccion);
}
