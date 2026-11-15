import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/domain/usecases/fijar_ubicacion_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';

/// Lleva el comercio del dueño: lo lee al entrar y lo registra desde el
/// formulario. El Home del comercio decide qué mostrar según su estado.
class ComercioBloc extends Bloc<ComercioEvent, ComercioState> {
  final GetMiComercioUseCase _getMine;
  final RegistrarComercioUseCase _registrar;
  final FijarUbicacionComercioUseCase _fijarUbicacion;
  final ObtenerUbicacionUseCase _obtenerUbicacion;

  ComercioBloc({
    required GetMiComercioUseCase getMine,
    required RegistrarComercioUseCase registrar,
    required FijarUbicacionComercioUseCase fijarUbicacion,
    required ObtenerUbicacionUseCase obtenerUbicacion,
  })  : _getMine = getMine,
        _registrar = registrar,
        _fijarUbicacion = fijarUbicacion,
        _obtenerUbicacion = obtenerUbicacion,
        super(const ComercioState()) {
    on<ComercioStarted>(_onStarted);
    on<ComercioSubmitted>(_onSubmitted);
    on<ComercioUbicacionSolicitada>(_onUbicacionSolicitada);
  }

  Future<void> _onStarted(
    ComercioStarted event,
    Emitter<ComercioState> emit,
  ) async {
    emit(state.copyWith(status: ComercioStatus.loading));
    try {
      final comercio = await _getMine();
      emit(ComercioState(status: ComercioStatus.ready, comercio: comercio));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ComercioStatus.loadFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ComercioStatus.loadFailed,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }

  Future<void> _onSubmitted(
    ComercioSubmitted event,
    Emitter<ComercioState> emit,
  ) async {
    // Un segundo toque mientras se guarda el primero no debe reenviar.
    if (state.status == ComercioStatus.saving) return;
    emit(state.copyWith(status: ComercioStatus.saving));
    try {
      final comercio = await _registrar(event.datos);
      emit(ComercioState(status: ComercioStatus.ready, comercio: comercio));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ComercioStatus.saveFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ComercioStatus.saveFailed,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }

  /// HU-14: toma la ubicación del dueño. Con el comercio ya registrado la
  /// guarda en él; en el formulario de registro solo la conserva para
  /// enviarla con los demás datos. Si falla, se conserva lo que había y la
  /// pantalla muestra el motivo.
  Future<void> _onUbicacionSolicitada(
    ComercioUbicacionSolicitada event,
    Emitter<ComercioState> emit,
  ) async {
    // Un segundo toque mientras el GPS responde no debe repetirlo.
    if (state.status == ComercioStatus.locating) return;
    emit(state.copyWith(status: ComercioStatus.locating));
    try {
      if (state.comercio == null) {
        final ubicacion = await _obtenerUbicacion();
        emit(state.copyWith(status: ComercioStatus.ready, ubicacion: ubicacion));
        return;
      }
      final comercio = await _fijarUbicacion();
      emit(ComercioState(status: ComercioStatus.ready, comercio: comercio));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ComercioStatus.locationFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ComercioStatus.locationFailed,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
