import 'package:smartcart/features/estadisticas/domain/entities/estadisticas_plataforma.dart';

/// Contrato de las estadísticas del panel del administrador (HU-28).
abstract class EstadisticasRepository {
  /// Las cifras en este momento. La base solo las entrega al administrador.
  Future<EstadisticasPlataforma> obtener();
}
