import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/usecases/validacion_usecases.dart';

/// Algo que la persona hace con un reporte dudoso (HU-15).
abstract class AccionReporteEvent {
  final String idReporte;

  AccionReporteEvent(this.idReporte);
}

/// Otro colaborador confirma el reporte.
class ReporteConfirmadoPorColaborador extends AccionReporteEvent {
  ReporteConfirmadoPorColaborador(super.idReporte);
}

/// El comercio confirma el reporte.
class ReporteConfirmadoPorComercio extends AccionReporteEvent {
  ReporteConfirmadoPorComercio(super.idReporte);
}

/// El comercio corrige el precio del reporte.
class ReporteCorregidoPorComercio extends AccionReporteEvent {
  final int precio;

  ReporteCorregidoPorComercio(super.idReporte, this.precio);
}

enum AccionReporteStatus { initial, loading, success, failure }

/// Estado único de la acción sobre un reporte. [exitos] cuenta las acciones
/// guardadas: la pantalla reacciona a que cambie para recargar su lista, sin
/// perder el aviso si dos acciones seguidas salen igual.
class AccionReporteState {
  final AccionReporteStatus status;
  final int exitos;

  /// Qué reporte se está procesando (para mostrarle el indicador).
  final String? idEnProceso;
  final String? mensaje;

  const AccionReporteState({
    this.status = AccionReporteStatus.initial,
    this.exitos = 0,
    this.idEnProceso,
    this.mensaje,
  });

  @override
  String toString() =>
      'AccionReporteState(${status.name}, exitos: $exitos, mensaje: $mensaje)';
}

/// Convierte "confirmar" y "corregir" en llamadas a los casos de uso de la
/// HU-15. Atiende una acción a la vez: un segundo toque mientras se procesa
/// la primera no la repite.
class AccionReporteBloc extends Bloc<AccionReporteEvent, AccionReporteState> {
  final ConfirmarReporteColaboradorUseCase _confirmarColaborador;
  final ConfirmarReporteComercioUseCase _confirmarComercio;
  final CorregirReporteComercioUseCase _corregirComercio;

  AccionReporteBloc({
    required ConfirmarReporteColaboradorUseCase confirmarColaborador,
    required ConfirmarReporteComercioUseCase confirmarComercio,
    required CorregirReporteComercioUseCase corregirComercio,
  })  : _confirmarColaborador = confirmarColaborador,
        _confirmarComercio = confirmarComercio,
        _corregirComercio = corregirComercio,
        super(const AccionReporteState()) {
    on<ReporteConfirmadoPorColaborador>(
      (e, emit) => _run(
        emit,
        e,
        'Confirmaste el reporte. ¡Gracias por ayudar a la comunidad!',
        () => _confirmarColaborador(e.idReporte),
      ),
    );
    on<ReporteConfirmadoPorComercio>(
      (e, emit) => _run(
        emit,
        e,
        'Confirmaste el precio. El reporte quedó validado.',
        () => _confirmarComercio(e.idReporte),
      ),
    );
    on<ReporteCorregidoPorComercio>(
      (e, emit) => _run(
        emit,
        e,
        'Corregiste el precio. Quedó con el valor que indicaste.',
        () => _corregirComercio(e.idReporte, e.precio),
      ),
    );
  }

  Future<void> _run(
    Emitter<AccionReporteState> emit,
    AccionReporteEvent evento,
    String mensajeExito,
    Future<void> Function() accion,
  ) async {
    if (state.status == AccionReporteStatus.loading) return;
    emit(AccionReporteState(
      status: AccionReporteStatus.loading,
      exitos: state.exitos,
      idEnProceso: evento.idReporte,
    ));
    try {
      await accion();
      emit(AccionReporteState(
        status: AccionReporteStatus.success,
        exitos: state.exitos + 1,
        mensaje: mensajeExito,
      ));
    } on AuthFailure catch (e) {
      emit(AccionReporteState(
        status: AccionReporteStatus.failure,
        exitos: state.exitos,
        mensaje: e.message,
      ));
    } catch (_) {
      emit(AccionReporteState(
        status: AccionReporteStatus.failure,
        exitos: state.exitos,
        mensaje: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }
}
