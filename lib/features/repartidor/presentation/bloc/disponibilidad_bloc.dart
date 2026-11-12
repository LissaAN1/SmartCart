import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';

abstract class DisponibilidadEvent {}

/// La persona tocó el interruptor de disponibilidad.
class DisponibilidadCambiada extends DisponibilidadEvent {
  final bool disponible;

  DisponibilidadCambiada(this.disponible);

  @override
  String toString() => 'DisponibilidadCambiada($disponible)';
}

/// Estado de la disponibilidad del repartidor. El valor solo cambia cuando la
/// base de datos confirma el cambio; si falla se conserva el anterior.
class DisponibilidadState {
  final bool disponible;
  final bool guardando;
  final String? errorMessage;

  const DisponibilidadState({
    required this.disponible,
    this.guardando = false,
    this.errorMessage,
  });

  @override
  String toString() => 'DisponibilidadState($disponible, guardando: '
      '$guardando, error: $errorMessage)';
}

class DisponibilidadBloc
    extends Bloc<DisponibilidadEvent, DisponibilidadState> {
  final CambiarDisponibilidadUseCase _cambiar;

  DisponibilidadBloc({
    required CambiarDisponibilidadUseCase cambiar,
    required bool inicial,
  })  : _cambiar = cambiar,
        super(DisponibilidadState(disponible: inicial)) {
    on<DisponibilidadCambiada>(_onCambiada);
  }

  Future<void> _onCambiada(
    DisponibilidadCambiada event,
    Emitter<DisponibilidadState> emit,
  ) async {
    if (state.guardando) return;
    emit(DisponibilidadState(disponible: state.disponible, guardando: true));
    try {
      await _cambiar(event.disponible);
      emit(DisponibilidadState(disponible: event.disponible));
    } on AuthFailure catch (e) {
      emit(DisponibilidadState(
          disponible: state.disponible, errorMessage: e.message));
    } catch (_) {
      emit(DisponibilidadState(
        disponible: state.disponible,
        errorMessage: 'No pudimos cambiar tu disponibilidad. Inténtalo de nuevo.',
      ));
    }
  }
}
