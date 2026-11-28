/// A quién se califica en una orden completada.
enum TipoCalificacion {
  comercio('comercio', 'el comercio'),
  repartidor('repartidor', 'el repartidor');

  const TipoCalificacion(this.dbName, this.etiqueta);

  /// Valor que recibe `calificar_orden` y guarda `calificacion.tipo`.
  final String dbName;

  /// Para frases como "Califica a el comercio" → se usa en títulos.
  final String etiqueta;

  String get titulo =>
      this == comercio ? 'Calificar al comercio' : 'Calificar al repartidor';
}

/// El promedio y el total de calificaciones de un comercio o repartidor.
class ResumenCalificaciones {
  /// `null` mientras no tenga calificaciones.
  final double? promedio;
  final int total;

  const ResumenCalificaciones({this.promedio, this.total = 0});

  static const sinCalificaciones = ResumenCalificaciones();

  bool get tiene => promedio != null && total > 0;

  /// "Sin calificaciones" o, por ejemplo, "4.5 (12)".
  String get etiqueta =>
      tiene ? '${promedio!.toStringAsFixed(1)} ($total)' : 'Sin calificaciones';
}
