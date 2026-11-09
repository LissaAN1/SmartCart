import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_event.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_state.dart';

/// Lleva el comercio del dueño: lo lee al entrar y lo registra desde el
/// formulario. El Home del comercio decide qué mostrar según su estado.
class ComercioBloc extends Bloc<ComercioEvent, ComercioState> {
  final GetMiComercioUseCase _getMine;
  final RegistrarComercioUseCase _registrar;

  ComercioBloc({
    required GetMiComercioUseCase getMine,
    required RegistrarComercioUseCase registrar,
  })  : _getMine = getMine,
        _registrar = registrar,
        super(const ComercioState()) {
    on<ComercioStarted>(_onStarted);
    on<ComercioSubmitted>(_onSubmitted);
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
}
