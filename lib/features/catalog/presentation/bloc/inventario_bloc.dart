import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_encabezado_catalogo_usecase.dart';

abstract class InventarioEvent {}

/// Al abrir el catálogo y cada vez que cambia: carga chips y resumen.
class InventarioStarted extends InventarioEvent {}

enum InventarioStatus { initial, loading, ready, failed }

class InventarioState {
  final InventarioStatus status;
  final EncabezadoCatalogo? encabezado;

  const InventarioState({
    this.status = InventarioStatus.initial,
    this.encabezado,
  });
}

/// HU-11: parte de arriba del catálogo (chips de categorías y resumen del
/// inventario). La lista en sí la maneja `CatalogoListaBloc`; los cambios de
/// cada producto se hacen en Editar Producto.
class InventarioBloc extends Bloc<InventarioEvent, InventarioState> {
  final GetEncabezadoCatalogoUseCase _encabezado;

  InventarioBloc({required GetEncabezadoCatalogoUseCase encabezado})
      : _encabezado = encabezado,
        super(const InventarioState()) {
    on<InventarioStarted>(_onStarted);
  }

  Future<void> _onStarted(
    InventarioStarted event,
    Emitter<InventarioState> emit,
  ) async {
    // Mientras recarga se conserva el encabezado anterior.
    emit(InventarioState(
      status: InventarioStatus.loading,
      encabezado: state.encabezado,
    ));
    try {
      final encabezado = await _encabezado();
      emit(InventarioState(
          status: InventarioStatus.ready, encabezado: encabezado));
    } catch (_) {
      // La lista ya muestra el motivo (por ejemplo, comercio pendiente).
      emit(InventarioState(
          status: InventarioStatus.failed, encabezado: state.encabezado));
    }
  }
}
