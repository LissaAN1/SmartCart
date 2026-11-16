/// Qué pasó al reportar un precio incorrecto.
enum ResultadoReporte {
  /// Se guardó un reporte nuevo, pendiente de revisión.
  registrado,

  /// El cliente ya había reportado ese precio y su reporte sigue pendiente:
  /// no se crea otro.
  yaReportado,
}

/// Contrato de los reportes de precio incorrecto (HU-13, escenario 3).
abstract class ReporteIncorrectoRepository {
  /// Guarda un reporte pendiente del precio vigente de [idProducto], con un
  /// [motivo] opcional.
  Future<ResultadoReporte> reportar(String idProducto, {String? motivo});
}
