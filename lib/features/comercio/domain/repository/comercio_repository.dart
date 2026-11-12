import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// Contrato para registrar y consultar el comercio de una cuenta.
abstract class ComercioRepository {
  /// El comercio del dueño [userId], o `null` si todavía no lo registró.
  Future<Comercio?> getMine(String userId);

  /// Guarda el comercio de [userId] con estado pendiente y lo devuelve.
  Future<Comercio> register(String userId, ComercioDatos datos);
}
