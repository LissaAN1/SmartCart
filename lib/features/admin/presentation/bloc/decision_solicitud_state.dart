enum DecisionStatus { initial, loading, success, failure }

/// Estado único de la pantalla de detalle de una solicitud.
class DecisionSolicitudState {
  final DecisionStatus status;

  /// Qué se decidió; solo tiene valor en `success`.
  final bool? aprobada;
  final String? errorMessage;

  const DecisionSolicitudState({
    this.status = DecisionStatus.initial,
    this.aprobada,
    this.errorMessage,
  });

  @override
  String toString() => 'DecisionSolicitudState(${status.name}, '
      'aprobada: $aprobada, error: $errorMessage)';
}
