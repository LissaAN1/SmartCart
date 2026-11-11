import 'package:smartcart/features/admin/domain/entities/solicitud_aprobacion.dart';

/// Algo que el administrador le pide al DecisionSolicitudBloc.
abstract class DecisionSolicitudEvent {
  final SolicitudAprobacion solicitud;

  DecisionSolicitudEvent(this.solicitud);
}

/// Presionó "Aprobar".
class SolicitudAprobada extends DecisionSolicitudEvent {
  SolicitudAprobada(super.solicitud);

  @override
  String toString() => 'SolicitudAprobada(${solicitud.nombre})';
}

/// Presionó "Rechazar" y escribió un [motivo] (puede venir vacío: el caso de
/// uso lo rechaza).
class SolicitudRechazada extends DecisionSolicitudEvent {
  final String? motivo;

  SolicitudRechazada(super.solicitud, this.motivo);

  @override
  String toString() => 'SolicitudRechazada(${solicitud.nombre})';
}
