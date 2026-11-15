import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/usecases/enviar_reporte_precio_usecase.dart';
import 'package:smartcart/features/reportes/domain/usecases/tomar_foto_usecase.dart';

abstract class ReporteFormEvent {}

/// La persona presionó "Tomar foto" (o "Cambiar foto").
class ReporteFotoSolicitada extends ReporteFormEvent {}

/// La persona quitó la foto que había tomado.
class ReporteFotoQuitada extends ReporteFormEvent {}

/// La persona presionó "Enviar reporte". La foto la guarda el Bloc.
class ReporteEnviado extends ReporteFormEvent {
  final ReporteDatos datos;

  ReporteEnviado(this.datos);
}

enum ReporteFormStatus {
  initial,
  tomandoFoto,
  fotoFallida,
  enviando,
  enviado,
  envioFallido,
}

class ReporteFormState {
  final ReporteFormStatus status;
  final FotoReporte? foto;
  final String? errorMessage;

  const ReporteFormState({
    this.status = ReporteFormStatus.initial,
    this.foto,
    this.errorMessage,
  });

  /// La foto se conserva entre estados; el error no se arrastra.
  ReporteFormState copyWith({
    ReporteFormStatus? status,
    FotoReporte? foto,
    bool quitarFoto = false,
    String? errorMessage,
  }) {
    return ReporteFormState(
      status: status ?? this.status,
      foto: quitarFoto ? null : (foto ?? this.foto),
      errorMessage: errorMessage,
    );
  }
}

/// Formulario del reporte de precio: lleva la foto de la etiqueta y envía el
/// reporte. Al terminar deja el estado en `enviado` y la pantalla avisa que
/// el reporte quedó pendiente de revisión.
class ReporteFormBloc extends Bloc<ReporteFormEvent, ReporteFormState> {
  final TomarFotoUseCase _tomarFoto;
  final EnviarReportePrecioUseCase _enviar;

  ReporteFormBloc({
    required TomarFotoUseCase tomarFoto,
    required EnviarReportePrecioUseCase enviar,
  })  : _tomarFoto = tomarFoto,
        _enviar = enviar,
        super(const ReporteFormState()) {
    on<ReporteFotoSolicitada>(_onFotoSolicitada);
    on<ReporteFotoQuitada>(
      (event, emit) => emit(state.copyWith(
        status: ReporteFormStatus.initial,
        quitarFoto: true,
      )),
    );
    on<ReporteEnviado>(_onEnviado);
  }

  bool get _ocupado =>
      state.status == ReporteFormStatus.tomandoFoto ||
      state.status == ReporteFormStatus.enviando;

  Future<void> _onFotoSolicitada(
    ReporteFotoSolicitada event,
    Emitter<ReporteFormState> emit,
  ) async {
    if (_ocupado) return;
    emit(state.copyWith(status: ReporteFormStatus.tomandoFoto));
    try {
      final foto = await _tomarFoto();
      // Cancelar la cámara no es un error: se queda con la foto anterior.
      emit(state.copyWith(status: ReporteFormStatus.initial, foto: foto));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ReporteFormStatus.fotoFallida, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ReporteFormStatus.fotoFallida,
        errorMessage: 'No pudimos tomar la foto. Inténtalo de nuevo.',
      ));
    }
  }

  Future<void> _onEnviado(
    ReporteEnviado event,
    Emitter<ReporteFormState> emit,
  ) async {
    // Un segundo toque mientras se envía el primero no debe reenviar.
    if (_ocupado) return;
    emit(state.copyWith(status: ReporteFormStatus.enviando));
    try {
      await _enviar(event.datos, state.foto);
      emit(state.copyWith(status: ReporteFormStatus.enviado));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: ReporteFormStatus.envioFallido, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        status: ReporteFormStatus.envioFallido,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
