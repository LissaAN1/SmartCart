import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Contrato para registrar y consultar el comercio de una cuenta.
abstract class ComercioRepository {
  /// El comercio del dueño [userId], o `null` si todavía no lo registró.
  Future<Comercio?> getMine(String userId);

  /// Guarda el comercio de [userId] con estado pendiente y lo devuelve.
  Future<Comercio> register(String userId, ComercioDatos datos);

  /// Guarda las coordenadas del comercio de la cuenta con sesión iniciada
  /// (HU-14). Sirve también cuando el comercio ya está aprobado.
  Future<void> fijarUbicacion(Ubicacion ubicacion);
}
