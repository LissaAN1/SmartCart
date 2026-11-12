/// Algo que el detalle de una solicitud le pide al DecisionSolicitudBloc.
abstract class DecisionSolicitudEvent {}

/// El administrador presionó "Aprobar".
class AprobacionSolicitada extends DecisionSolicitudEvent {
  @override
  String toString() => 'AprobacionSolicitada()';
}

/// El administrador confirmó el rechazo con su [motivo].
class RechazoSolicitado extends DecisionSolicitudEvent {
  final String motivo;

  RechazoSolicitado(this.motivo);

  @override
  String toString() => 'RechazoSolicitado($motivo)';
}
