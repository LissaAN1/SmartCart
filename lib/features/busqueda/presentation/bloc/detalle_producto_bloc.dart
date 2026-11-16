import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/usecases/get_detalle_producto_usecase.dart';

abstract class DetalleProductoEvent {}

/// Al abrir la pantalla y al reintentar.
class DetalleProductoStarted extends DetalleProductoEvent {}

enum DetalleProductoStatus { initial, loading, failed, ready }

class DetalleProductoState {
  final DetalleProductoStatus status;
  final DetalleProducto? detalle;
  final String? errorMessage;

  const DetalleProductoState({
    this.status = DetalleProductoStatus.initial,
    this.detalle,
    this.errorMessage,
  });
}

/// HU-12 · escenario 2: un producto (de un resultado o de un código
/// escaneado) con el precio de cada establecimiento.
class DetalleProductoBloc
    extends Bloc<DetalleProductoEvent, DetalleProductoState> {
  final ConsultaProducto consulta;
  final GetDetalleProductoUseCase _detalle;

  DetalleProductoBloc({
    required this.consulta,
    required GetDetalleProductoUseCase detalle,
  })  : _detalle = detalle,
        super(const DetalleProductoState()) {
    on<DetalleProductoStarted>(_onStarted);
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
}
