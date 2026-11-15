/// Reglas del reporte de precios (HU-14) que comparten la app y la base.
abstract final class ReporteReglas {
  /// Distancia máxima, en metros, entre el colaborador y el establecimiento.
  /// El backlog solo dice "dentro del establecimiento"; 150 m deja margen al
  /// error normal del GPS. El mismo valor está en `enviar_reporte_precio`
  /// (docs/sql/sprint2_hu14.sql).
  static const radioMaximoM = 150.0;

  static bool estaDentro(double distanciaM) => distanciaM <= radioMaximoM;

  /// Mensaje cuando el colaborador está lejos. La base responde con el mismo
  /// texto, así la persona lee lo mismo venga de donde venga.
  static String mensajeFuera(double distanciaM) =>
      'Debes estar en el establecimiento para reportar el precio. '
      'Estás a ${distanciaM.round()} m.';
}
