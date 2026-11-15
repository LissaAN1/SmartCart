/// En qué punto de la revisión está un reporte. Los reportes nacen
/// pendientes; validarlos o rechazarlos es de la HU-15.
enum EstadoReporte {
  pendiente,
  validado,
  rechazado;

  /// Valor guardado en la columna `estado`. Un valor desconocido se trata
  /// como pendiente: nunca se muestra como validado algo que no lo es.
  static EstadoReporte fromDbName(String? value) {
    for (final estado in EstadoReporte.values) {
      if (estado.name == value) return estado;
    }
    return EstadoReporte.pendiente;
  }
}

/// Un reporte que el colaborador ya envió, tal como se ve en su historial.
class MiReporte {
  final String id;

  /// Nombre del producto reportado.
  final String producto;

  /// Nombre del establecimiento donde se reportó.
  final String establecimiento;

  /// Precio en pesos colombianos (COP).
  final int precio;
  final int? precioPromocional;
  final bool agotado;
  final EstadoReporte estado;
  final DateTime creadoEn;

  const MiReporte({
    required this.id,
    required this.producto,
    required this.establecimiento,
    required this.precio,
    required this.estado,
    required this.creadoEn,
    this.precioPromocional,
    this.agotado = false,
  });
}
