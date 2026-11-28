import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/seguimiento/domain/entities/detalle_orden.dart';
import 'package:smartcart/features/seguimiento/domain/usecases/seguimiento_usecases.dart';

abstract class DetalleOrdenEvent {}

/// Al abrir la pantalla y al reintentar.
class DetalleOrdenStarted extends DetalleOrdenEvent {}

/// Escenario 2: "Confirmar recogida" o "Confirmar recepción".
class RecepcionConfirmada extends DetalleOrdenEvent {}

enum DetalleOrdenStatus { initial, loading, failed, ready }

class DetalleOrdenState {
  final DetalleOrdenStatus status;
  final DetalleOrden? detalle;
  final bool confirmando;

  /// Se confirmó en esta pantalla: al volver, la lista debe recargarse.
  final bool huboCambios;
  final String? errorMessage;
  final AvisoUi? aviso;

  const DetalleOrdenState({
    this.status = DetalleOrdenStatus.initial,
    this.detalle,
    this.confirmando = false,
    this.huboCambios = false,
    this.errorMessage,
    this.aviso,
  });

  DetalleOrdenState copyWith({
    DetalleOrdenStatus? status,
    DetalleOrden? detalle,
    bool? confirmando,
    bool? huboCambios,
    String? errorMessage,
    AvisoUi? aviso,
  }) {
    return DetalleOrdenState(
      status: status ?? this.status,
      detalle: detalle ?? this.detalle,
      confirmando: confirmando ?? this.confirmando,
      huboCambios: huboCambios ?? this.huboCambios,
      errorMessage: errorMessage,
      aviso: aviso ?? this.aviso,
    );
  }
}

/// HU-23: el detalle de una orden y la confirmación de la recogida o la
/// recepción. Cada evento hace una sola llamada a un caso de uso.
class DetalleOrdenBloc extends Bloc<DetalleOrdenEvent, DetalleOrdenState> {
  final String idOrden;
  final GetDetalleOrdenUseCase _detalle;
  final ConfirmarRecepcionUseCase _confirmar;
  int _avisos = 0;

  DetalleOrdenBloc({
    required this.idOrden,
    required GetDetalleOrdenUseCase detalle,
    required ConfirmarRecepcionUseCase confirmar,
  })  : _detalle = detalle,
        _confirmar = confirmar,
        super(const DetalleOrdenState()) {
    on<DetalleOrdenStarted>(_onStarted);
    on<RecepcionConfirmada>(_onConfirmada);
  }

  Future<void> _onStarted(
    DetalleOrdenStarted event,
    Emitter<DetalleOrdenState> emit,
  ) async {
    emit(state.copyWith(status: DetalleOrdenStatus.loading));
    try {
      final detalle = await _detalle(idOrden);
      emit(state.copyWith(status: DetalleOrdenStatus.ready, detalle: detalle));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: DetalleOrdenStatus.failed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
          status: DetalleOrdenStatus.failed, errorMessage: _inesperado));
    }
  }

  Future<void> _onConfirmada(
    RecepcionConfirmada event,
    Emitter<DetalleOrdenState> emit,
  ) async {
    final detalle = state.detalle;
    // Un segundo toque mientras se envía no confirma dos veces.
    if (detalle == null || state.confirmando) return;
    emit(state.copyWith(confirmando: true));
    try {
      final actualizado = await _confirmar(detalle);
      emit(state.copyWith(
        detalle: actualizado,
        confirmando: false,
        huboCambios: true,
        aviso: _aviso('¡Listo! Cerramos tu orden. Gracias por tu compra.'),
      ));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          confirmando: false, aviso: _aviso(e.message, esError: true)));
    } catch (_) {
      emit(state.copyWith(
          confirmando: false, aviso: _aviso(_inesperado, esError: true)));
    }
  }

  AvisoUi _aviso(String texto, {bool esError = false}) =>
      AvisoUi(id: ++_avisos, texto: texto, esError: esError);

  static const _inesperado = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
