import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';
import 'package:smartcart/features/confianza/domain/usecases/reportar_precio_incorrecto_usecase.dart';

abstract class DetalleProductoEvent {}

/// Al abrir la pantalla y al reintentar.
class DetalleProductoStarted extends DetalleProductoEvent {}

/// HU-13, escenario 3: el cliente reporta que el precio de [idProducto] (el
/// producto de un establecimiento) no es el real.
class PrecioIncorrectoReportado extends DetalleProductoEvent {
  final String idProducto;
  final String? motivo;

  PrecioIncorrectoReportado(this.idProducto, {this.motivo});
}

enum DetalleProductoStatus { initial, loading, failed, ready }

class DetalleProductoState {
  final DetalleProductoStatus status;
  final DetalleProducto? detalle;
  final String? errorMessage;

  /// Productos cuyo reporte se está enviando ahora: su botón no acepta otro
  /// toque.
  final Set<String> reportando;

  /// Productos cuyo precio ya reportó el cliente en esta pantalla (o que ya
  /// tenían un reporte pendiente): se muestran como "Reporte enviado".
  final Set<String> reportados;

  /// Último mensaje para el `SnackBar`; la pantalla lo muestra una vez.
  final AvisoUi? aviso;

  const DetalleProductoState({
    this.status = DetalleProductoStatus.initial,
    this.detalle,
    this.errorMessage,
    this.reportando = const {},
    this.reportados = const {},
    this.aviso,
  });

  DetalleProductoState copyWith({
    Set<String>? reportando,
    Set<String>? reportados,
    AvisoUi? aviso,
  }) =>
      DetalleProductoState(
        status: status,
        detalle: detalle,
        errorMessage: errorMessage,
        reportando: reportando ?? this.reportando,
        reportados: reportados ?? this.reportados,
        aviso: aviso ?? this.aviso,
      );
}

/// HU-12 · escenario 2: un producto (de un resultado o de un código
/// escaneado) con el precio de cada establecimiento.
/// HU-13 · escenario 3: desde ese detalle se puede reportar un precio
/// incorrecto.
class DetalleProductoBloc
    extends Bloc<DetalleProductoEvent, DetalleProductoState> {
  final ConsultaProducto consulta;
  final GetDetalleProductoUseCase _detalle;
  final ReportarPrecioIncorrectoUseCase _reportar;
  int _avisos = 0;

  DetalleProductoBloc({
    required this.consulta,
    required GetDetalleProductoUseCase detalle,
    required ReportarPrecioIncorrectoUseCase reportar,
  })  : _detalle = detalle,
        _reportar = reportar,
        super(const DetalleProductoState()) {
    on<DetalleProductoStarted>(_onStarted);
    on<PrecioIncorrectoReportado>(_onReportado);
  }

  Future<void> _onStarted(
    DetalleProductoStarted event,
    Emitter<DetalleProductoState> emit,
  ) async {
    emit(const DetalleProductoState(status: DetalleProductoStatus.loading));
    try {
      final detalle = await _detalle(consulta);
      emit(DetalleProductoState(
        status: DetalleProductoStatus.ready,
        detalle: detalle,
      ));
    } on AuthFailure catch (e) {
      emit(DetalleProductoState(
        status: DetalleProductoStatus.failed,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(const DetalleProductoState(
        status: DetalleProductoStatus.failed,
        errorMessage: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
      ));
    }
  }

  Future<void> _onReportado(
    PrecioIncorrectoReportado event,
    Emitter<DetalleProductoState> emit,
  ) async {
    final id = event.idProducto;
    // Un segundo toque mientras se envía, o sobre un precio ya reportado, no
    // hace nada: así no se mandan dos reportes iguales.
    if (state.reportando.contains(id) || state.reportados.contains(id)) return;

    emit(state.copyWith(reportando: {...state.reportando, id}));
    try {
      final resultado = await _reportar(id, motivo: event.motivo);
      emit(state.copyWith(
        reportando: _sin(id),
        reportados: {...state.reportados, id},
        aviso: _aviso(
          switch (resultado) {
            ResultadoReporte.registrado =>
              'Gracias, enviamos tu reporte para revisarlo.',
            ResultadoReporte.yaReportado =>
              'Ya reportaste este precio; lo estamos revisando.',
          },
        ),
      ));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
        reportando: _sin(id),
        aviso: _aviso(e.message, esError: true),
      ));
    } catch (_) {
      emit(state.copyWith(
        reportando: _sin(id),
        aviso: _aviso('No pudimos enviar el reporte. Inténtalo de nuevo.',
            esError: true),
      ));
    }
  }

  /// Los que se están enviando ahora, menos [id]. Se calcula al emitir (no
  /// antes de esperar) porque dos reportes de productos distintos pueden
  /// estar en curso a la vez.
  Set<String> _sin(String id) => {...state.reportando}..remove(id);

  AvisoUi _aviso(String texto, {bool esError = false}) =>
      AvisoUi(id: ++_avisos, texto: texto, esError: esError);
}
