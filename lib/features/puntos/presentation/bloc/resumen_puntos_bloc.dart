import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/usecases/get_resumen_puntos_usecase.dart';

abstract class ResumenPuntosEvent {}

/// Leer (o volver a leer) los puntos, el nivel y la reputación.
class ResumenPuntosStarted extends ResumenPuntosEvent {
  @override
  String toString() => 'ResumenPuntosStarted()';
}

enum ResumenPuntosStatus { initial, loading, success, failure }

/// Estado único de la tarjeta de puntos.
class ResumenPuntosState {
  final ResumenPuntosStatus status;
  final ResumenPuntos? resumen;
  final String? errorMessage;

  const ResumenPuntosState({
    this.status = ResumenPuntosStatus.initial,
    this.resumen,
    this.errorMessage,
  });

  @override
  String toString() =>
      'ResumenPuntosState(${status.name}, error: $errorMessage)';
}

class ResumenPuntosBloc extends Bloc<ResumenPuntosEvent, ResumenPuntosState> {
  final GetResumenPuntosUseCase _getResumen;

  ResumenPuntosBloc({required GetResumenPuntosUseCase getResumen})
      : _getResumen = getResumen,
        super(const ResumenPuntosState()) {
    on<ResumenPuntosStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ResumenPuntosStarted event,
    Emitter<ResumenPuntosState> emit,
  ) async {
    if (state.status == ResumenPuntosStatus.loading) return;
    // Si ya había un resumen se conserva mientras se vuelve a leer.
    emit(ResumenPuntosState(
        status: ResumenPuntosStatus.loading, resumen: state.resumen));
    try {
      final resumen = await _getResumen();
      emit(ResumenPuntosState(
          status: ResumenPuntosStatus.success, resumen: resumen));
    } on AuthFailure catch (e) {
      emit(ResumenPuntosState(
        status: ResumenPuntosStatus.failure,
        resumen: state.resumen,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(ResumenPuntosState(
        status: ResumenPuntosStatus.failure,
        resumen: state.resumen,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
