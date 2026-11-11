import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/admin/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_event.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_state.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';

/// Convierte "Aprobar" y "Rechazar" en llamadas a DecidirSolicitudUseCase.
class DecisionSolicitudBloc
    extends Bloc<DecisionSolicitudEvent, DecisionSolicitudState> {
  final DecidirSolicitudUseCase _decidir;

  DecisionSolicitudBloc({required DecidirSolicitudUseCase decidir})
      : _decidir = decidir,
        super(const DecisionSolicitudState()) {
    on<SolicitudAprobada>(
      (event, emit) => _run(emit, true, () => _decidir.aprobar(event.solicitud)),
    );
    on<SolicitudRechazada>(
      (event, emit) => _run(
        emit,
        false,
        () => _decidir.rechazar(event.solicitud, event.motivo),
      ),
    );
  }

  Future<void> _run(
    Emitter<DecisionSolicitudState> emit,
    bool aprobada,
    Future<void> Function() action,
  ) async {
    // Un segundo toque mientras se procesa el primero no debe reenviar.
    if (state.status == DecisionStatus.loading) return;
    emit(const DecisionSolicitudState(status: DecisionStatus.loading));
    try {
      await action();
      emit(DecisionSolicitudState(
          status: DecisionStatus.success, aprobada: aprobada));
    } on AuthFailure catch (e) {
      emit(DecisionSolicitudState(
          status: DecisionStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(const DecisionSolicitudState(
        status: DecisionStatus.failure,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
