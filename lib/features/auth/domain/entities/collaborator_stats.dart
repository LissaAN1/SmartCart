/// Datos de la fila `perfil_colaborador` de una cuenta: lo que se muestra del
/// modo Colaborador (puntos, nivel y reputación).
class CollaboratorStats {
  final int points;
  final int level;
  final num reputation;

  const CollaboratorStats({
    required this.points,
    required this.level,
    required this.reputation,
  });

  /// Reputación sin decimales de más: "0", "4" o "4.5".
  String get reputationLabel {
    final value = reputation.toDouble();
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  /// Valores con los que se crea el perfil al activar el modo (HU-06):
  /// 0 puntos, nivel 1 y reputación 0.
  static const initial = CollaboratorStats(points: 0, level: 1, reputation: 0);
}
