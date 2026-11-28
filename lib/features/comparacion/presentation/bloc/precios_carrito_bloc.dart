import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/comparacion/domain/usecases/comparacion_usecases.dart';
import 'package:smartcart/features/comparacion/domain/valor_carrito.dart';

abstract class PreciosCarritoEvent {}

/// Leer (o volver a leer) el precio vigente de cada producto del carrito.
class PreciosCarritoSolicitados extends PreciosCarritoEvent {}

enum PreciosCarritoStatus { initial, cargando, listos, fallidos }

class PreciosCarritoState {
  final PreciosCarritoStatus status;

  /// Precio de cada producto del carrito, por id de producto.
  final Map<String, PrecioLinea> precios;
  final String? errorMessage;

  const PreciosCarritoState({
    this.status = PreciosCarritoStatus.initial,
    this.precios = const {},
    this.errorMessage,
  });
}

/// HU-18: el precio vigente de cada producto del carrito, para mostrar el
/// subtotal de cada línea y el total. Las cantidades siguen siendo las del
/// `CarritoBloc` (HU-17); aquí solo están los precios.
class PreciosCarritoBloc extends Bloc<PreciosCarritoEvent, PreciosCarritoState> {
  final GetOfertasCarritoUseCase _ofertas;

  PreciosCarritoBloc({required GetOfertasCarritoUseCase ofertas})
      : _ofertas = ofertas,
        super(const PreciosCarritoState()) {
    on<PreciosCarritoSolicitados>(_onSolicitados);
  }

  Future<void> _onSolicitados(
    PreciosCarritoSolicitados event,
    Emitter<PreciosCarritoState> emit,
  ) async {
    emit(PreciosCarritoState(
      status: PreciosCarritoStatus.cargando,
      precios: state.precios,
    ));
    try {
      final lineas = await _ofertas();
      emit(PreciosCarritoState(
        status: PreciosCarritoStatus.listos,
        precios: {
          for (final l in lineas) l.idProducto: PrecioLinea.de(l.ofertaActual),
        },
      ));
    } catch (e) {
      emit(PreciosCarritoState(
        status: PreciosCarritoStatus.fallidos,
        precios: state.precios,
        errorMessage: e is AuthFailure
            ? e.message
            : 'No pudimos cargar los precios del carrito.',
      ));
    }
  }
}
