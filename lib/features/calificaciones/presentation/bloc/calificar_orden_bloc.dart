import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/calificaciones/domain/calificacion_reglas.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/domain/usecases/calificar_orden_usecase.dart';

abstract class CalificarOrdenEvent {}

/// El cliente tocó una estrella.
class EstrellasElegidas extends CalificarOrdenEvent {
  final int estrellas;

  EstrellasElegidas(this.estrellas);
}

/// El cliente escribió o cambió el comentario.
class ComentarioCambiado extends CalificarOrdenEvent {
  final String comentario;

  ComentarioCambiado(this.comentario);
}

/// El cliente presionó "Enviar calificación".
class CalificacionEnviada extends CalificarOrdenEvent {}

enum CalificarOrdenStatus { editando, enviando, enviada }

class CalificarOrdenState {
  final CalificarOrdenStatus status;

  /// 0 mientras no elige ninguna.
  final int estrellas;
  final String comentario;

  /// Por qué no se pudo enviar (la base rechazó o no hubo red).
  final String? errorMessage;

  /// El nuevo promedio de quien se calificó ([CalificarOrdenStatus.enviada]).
  final ResumenCalificaciones? resumen;

  const CalificarOrdenState({
    this.status = CalificarOrdenStatus.editando,
    this.estrellas = 0,
    this.comentario = '',
    this.errorMessage,
    this.resumen,
  });

  bool get puedeEnviar =>
      status == CalificarOrdenStatus.editando &&
      CalificacionReglas.validar(estrellas, comentario) == null;

  CalificarOrdenState copyWith({
    CalificarOrdenStatus? status,
    int? estrellas,
    String? comentario,
    String? errorMessage,
    ResumenCalificaciones? resumen,
  }) {
    return CalificarOrdenState(
      status: status ?? this.status,
      estrellas: estrellas ?? this.estrellas,
      comentario: comentario ?? this.comentario,
      errorMessage: errorMessage,
      resumen: resumen ?? this.resumen,
    );
  }
}

/// HU-25: la pantalla donde el cliente califica al comercio o al repartidor
/// de una orden completada.
class CalificarOrdenBloc
    extends Bloc<CalificarOrdenEvent, CalificarOrdenState> {
  final CalificarOrdenUseCase _calificar;
  final String idOrden;
  final TipoCalificacion tipo;

  CalificarOrdenBloc({
    required CalificarOrdenUseCase calificar,
    required this.idOrden,
    required this.tipo,
  })  : _calificar = calificar,
        super(const CalificarOrdenState()) {
    on<EstrellasElegidas>((event, emit) {
      if (state.status != CalificarOrdenStatus.editando) return;
      emit(state.copyWith(estrellas: event.estrellas));
    });
    on<ComentarioCambiado>((event, emit) {
      if (state.status != CalificarOrdenStatus.editando) return;
      emit(state.copyWith(comentario: event.comentario));
    });
    on<CalificacionEnviada>(_onEnviada);
  }

  Future<void> _onEnviada(
    CalificacionEnviada event,
    Emitter<CalificarOrdenState> emit,
  ) async {
    // Un segundo toque mientras se envía no califica dos veces.
    if (state.status != CalificarOrdenStatus.editando) return;
    emit(state.copyWith(status: CalificarOrdenStatus.enviando));
    try {
      final resumen = await _calificar(
        idOrden: idOrden,
        tipo: tipo,
        estrellas: state.estrellas,
        comentario: state.comentario,
      );
      emit(state.copyWith(
        status: CalificarOrdenStatus.enviada,
        resumen: resumen,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CalificarOrdenStatus.editando,
        errorMessage: e is AuthFailure
            ? e.message
            : 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
