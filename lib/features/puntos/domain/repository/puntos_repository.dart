import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';

/// Contrato de los puntos y la reputación del colaborador (HU-16). Los
/// puntos los asigna la base de datos cuando un reporte pasa a validado; la
/// app solo los lee.
abstract class PuntosRepository {
  /// Puntos, nivel y reputación de la cuenta con sesión iniciada.
  Future<ResumenPuntos> resumen();

  /// Los movimientos de puntos de la cuenta, del más reciente al más antiguo.
  Future<PagedResult<MovimientoPuntos>> movimientos(PageRequest request);
}
