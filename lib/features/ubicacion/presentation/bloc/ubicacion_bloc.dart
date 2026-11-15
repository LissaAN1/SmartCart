import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';

abstract class UbicacionEvent {}

/// Pedir (o volver a pedir) la ubicación actual.
class UbicacionSolicitada extends UbicacionEvent {}

enum UbicacionStatus { initial, cargando, lista, fallida }

class UbicacionState {
  final UbicacionStatus status;
  final Ubicacion? ubicacion;
  final String? errorMessage;

  const UbicacionState({
    this.status = UbicacionStatus.initial,
    this.ubicacion,
    this.errorMessage,
  });
}

/// Obtiene la ubicación de la persona para las pantallas que la necesitan
/// (registro del comercio y reporte de precios). Si falla, deja el mensaje y
/// la pantalla ofrece reintentar.
class UbicacionBloc extends Bloc<UbicacionEvent, UbicacionState> {
  final ObtenerUbicacionUseCase _obtener;

  UbicacionBloc({required ObtenerUbicacionUseCase obtener})
      : _obtener = obtener,
        super(const UbicacionState()) {
    on<UbicacionSolicitada>(_onSolicitada);
  }

  Future<void> _onSolicitada(
    UbicacionSolicitada event,
    Emitter<UbicacionState> emit,
  ) async {
    // Un segundo toque mientras el GPS responde no debe pedirla otra vez.
    if (state.status == UbicacionStatus.cargando) return;
    emit(UbicacionState(
      status: UbicacionStatus.cargando,
      ubicacion: state.ubicacion,
    ));
    try {
      emit(UbicacionState(
        status: UbicacionStatus.lista,
        ubicacion: await _obtener(),
      ));
    } on AuthFailure catch (e) {
      emit(UbicacionState(
        status: UbicacionStatus.fallida,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(const UbicacionState(
        status: UbicacionStatus.fallida,
        errorMessage: 'No pudimos conocer tu ubicación. Inténtalo de nuevo.',
      ));
    }
  }
}
