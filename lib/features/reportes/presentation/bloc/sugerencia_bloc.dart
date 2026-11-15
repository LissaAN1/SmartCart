import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/usecases/sugerir_establecimiento_usecase.dart';

abstract class SugerenciaEvent {}

/// La persona presionó "Enviar sugerencia".
class SugerenciaEnviada extends SugerenciaEvent {
  final SugerenciaDatos datos;

  SugerenciaEnviada(this.datos);
}

enum SugerenciaStatus { initial, enviando, enviada, fallida }

class SugerenciaState {
  final SugerenciaStatus status;
  final String? errorMessage;

  const SugerenciaState({
    this.status = SugerenciaStatus.initial,
    this.errorMessage,
  });
}

/// Sugerir un establecimiento que todavía no está en la plataforma.
class SugerenciaBloc extends Bloc<SugerenciaEvent, SugerenciaState> {
  final SugerirEstablecimientoUseCase _sugerir;

  SugerenciaBloc({required SugerirEstablecimientoUseCase sugerir})
      : _sugerir = sugerir,
        super(const SugerenciaState()) {
    on<SugerenciaEnviada>(_onEnviada);
  }

  Future<void> _onEnviada(
    SugerenciaEnviada event,
    Emitter<SugerenciaState> emit,
  ) async {
    // Un segundo toque mientras se envía el primero no debe repetirla.
    if (state.status == SugerenciaStatus.enviando) return;
    emit(const SugerenciaState(status: SugerenciaStatus.enviando));
    try {
      await _sugerir(event.datos);
      emit(const SugerenciaState(status: SugerenciaStatus.enviada));
    } on AuthFailure catch (e) {
      emit(SugerenciaState(
          status: SugerenciaStatus.fallida, errorMessage: e.message));
    } catch (_) {
      emit(const SugerenciaState(
        status: SugerenciaStatus.fallida,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
