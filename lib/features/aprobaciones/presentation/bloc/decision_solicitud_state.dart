import 'package:smartcart/core/domain/approval_status.dart';

enum DecisionSolicitudStatus { initial, loading, success, failure }

/// Estado único del detalle de una solicitud (HU-24).
class DecisionSolicitudState {
  final DecisionSolicitudStatus status;

  /// Decisión ya guardada ([ApprovalStatus.aprobado] o
  /// [ApprovalStatus.rechazado]); solo existe en `success`.
  final ApprovalStatus? decision;
  final String? errorMessage;

  const DecisionSolicitudState({
    this.status = DecisionSolicitudStatus.initial,
    this.decision,
    this.errorMessage,
  });

  bool get enviando => status == DecisionSolicitudStatus.loading;

  @override
  String toString() => 'DecisionSolicitudState(status: ${status.name}, '
      'decision: ${decision?.name}, error: $errorMessage)';
}
