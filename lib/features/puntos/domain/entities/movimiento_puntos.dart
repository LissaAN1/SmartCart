/// De dónde viene un movimiento de puntos.
enum TipoMovimientoPuntos {
  reporteValidado('reporte_validado'),
  canje('canje'),
  ajuste('ajuste');

  const TipoMovimientoPuntos(this.dbName);

  /// Valor guardado en `movimiento_puntos.tipo`.
  final String dbName;

  /// Un valor desconocido cuenta como ajuste.
  static TipoMovimientoPuntos fromDbName(String? value) {
    for (final tipo in TipoMovimientoPuntos.values) {
      if (tipo.dbName == value) return tipo;
    }
    return TipoMovimientoPuntos.ajuste;
  }
}

/// Una fila del historial de puntos del colaborador. [puntos] es positivo si
/// suma y negativo si resta (por ejemplo, un canje).
class MovimientoPuntos {
  final String id;
  final int puntos;
  final TipoMovimientoPuntos tipo;
  final String motivo;
  final DateTime creadoEn;

  const MovimientoPuntos({
    required this.id,
    required this.puntos,
    required this.tipo,
    required this.motivo,
    required this.creadoEn,
  });

  bool get suma => puntos >= 0;
}
