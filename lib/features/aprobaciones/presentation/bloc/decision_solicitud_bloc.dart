import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_event.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_state.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

/// Lleva la decisión del administrador sobre UNA solicitud. Las reglas
/// (motivo obligatorio, solo administrador) viven en el caso de uso; el Bloc
/// solo muestra su resultado.
class DecisionSolicitudBloc
    extends Bloc<DecisionSolicitudEvent, DecisionSolicitudState> {
  final Solicitud solicitud;
  final DecidirSolicitudUseCase _decidir;

  DecisionSolicitudBloc({
    required this.solicitud,
    required DecidirSolicitudUseCase decidir,
  })  : _decidir = decidir,
        super(const DecisionSolicitudState()) {
    on<AprobacionSolicitada>(
      (event, emit) => _ejecutar(
        emit,
        ApprovalStatus.aprobado,
        () => _decidir.aprobar(solicitud),
      ),
    );
    on<RechazoSolicitado>(
      (event, emit) => _ejecutar(
        emit,
        ApprovalStatus.rechazado,
        () => _decidir.rechazar(solicitud, motivo: event.motivo),
      ),
    );
  }

  Future<void> _ejecutar(
    Emitter<DecisionSolicitudState> emit,
    ApprovalStatus decision,
    Future<void> Function() accion,
  ) async {
    // Un segundo toque mientras se guarda el primero no debe reenviar, y una
    // solicitud ya decidida no se vuelve a decidir.
    if (state.enviando || state.status == DecisionSolicitudStatus.success) {
      return;
    }
    emit(const DecisionSolicitudState(status: DecisionSolicitudStatus.loading));
    try {
      await accion();
      emit(DecisionSolicitudState(
        status: DecisionSolicitudStatus.success,
        decision: decision,
      ));
    } on AuthFailure catch (e) {
      emit(DecisionSolicitudState(
        status: DecisionSolicitudStatus.failure,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(const DecisionSolicitudState(
        status: DecisionSolicitudStatus.failure,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
