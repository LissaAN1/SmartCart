/// Qué tan confiable es un precio (HU-13). Va de menor a mayor: el índice se
/// usa para subir y bajar de nivel en `ConfianzaReglas`.
enum NivelConfianza {
  bajo('Baja'),
  medio('Media'),
  alto('Alta');

  /// Texto que se muestra después de "Confianza": "Confianza alta".
  final String etiqueta;

  const NivelConfianza(this.etiqueta);
}

/// El resultado de evaluar un precio: su nivel de confianza, si ya pasó el
/// límite de días y cuántos días tiene.
class ConfianzaPrecio {
  final NivelConfianza nivel;

  /// `true` si el precio tiene más días que el límite que fijamos
  /// (`ConfianzaReglas.diasLimite`).
  final bool desactualizado;

  /// Días de calendario entre la última actualización y hoy: 0 es "hoy".
  final int dias;

  const ConfianzaPrecio({
    required this.nivel,
    required this.desactualizado,
    required this.dias,
  });

  /// "hoy", "ayer" o "hace 5 días", para escribir junto a la fecha.
  String get antiguedad => switch (dias) {
        0 => 'hoy',
        1 => 'ayer',
        _ => 'hace $dias días',
      };

  @override
  bool operator ==(Object other) =>
      other is ConfianzaPrecio &&
      other.nivel == nivel &&
      other.desactualizado == desactualizado &&
      other.dias == dias;

  @override
  int get hashCode => Object.hash(nivel, desactualizado, dias);

  @override
  String toString() =>
      'ConfianzaPrecio($nivel, desactualizado: $desactualizado, dias: $dias)';
}
