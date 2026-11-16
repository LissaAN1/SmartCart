import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_encabezado_catalogo_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/cambiar_disponibilidad_producto_usecase.dart';

abstract class InventarioEvent {}

/// Al abrir el catálogo y cada vez que cambia: carga chips y resumen.
class InventarioStarted extends InventarioEvent {}

/// HU-11 · escenario 2: el interruptor ACTIVO/INACTIVO de una tarjeta.
class DisponibilidadEnListaCambiada extends InventarioEvent {
  final Producto producto;
  final bool disponible;

  DisponibilidadEnListaCambiada(this.producto, this.disponible);
}

/// "Eliminar" del menú de una tarjeta, ya confirmado.
class ProductoEliminadoDeLista extends InventarioEvent {
  final Producto producto;

  ProductoEliminadoDeLista(this.producto);
}

enum InventarioStatus { initial, loading, ready, failed }

class InventarioState {
  final InventarioStatus status;
  final EncabezadoCatalogo? encabezado;

  /// Id del producto cuyo interruptor se está guardando.
  final String? cambiandoId;

  /// Producto que cambió (para reemplazarlo en la lista). Se emite una vez.
  final Producto? actualizado;

  /// Se eliminó un producto: la lista y el resumen deben recargarse.
  final bool eliminado;

  final String? errorMessage;

  const InventarioState({
    this.status = InventarioStatus.initial,
    this.encabezado,
    this.cambiandoId,
    this.actualizado,
    this.eliminado = false,
    this.errorMessage,
  });

  /// Lo que se muestra una sola vez (actualizado, eliminado, error) no se
  /// arrastra al siguiente estado.
  InventarioState copyWith({
    InventarioStatus? status,
    EncabezadoCatalogo? encabezado,
    String? cambiandoId,
    Producto? actualizado,
    bool eliminado = false,
    String? errorMessage,
  }) {
    return InventarioState(
      status: status ?? this.status,
      encabezado: encabezado ?? this.encabezado,
      cambiandoId: cambiandoId,
      actualizado: actualizado,
      eliminado: eliminado,
      errorMessage: errorMessage,
    );
  }
}

/// Parte de arriba del catálogo (chips y resumen) y las acciones rápidas de
/// cada tarjeta. La lista en sí la maneja `CatalogoListaBloc`.
class InventarioBloc extends Bloc<InventarioEvent, InventarioState> {
  final GetEncabezadoCatalogoUseCase _encabezado;
  final CambiarDisponibilidadProductoUseCase _disponibilidad;
  final EliminarProductoUseCase _eliminar;

  InventarioBloc({
    required GetEncabezadoCatalogoUseCase encabezado,
    required CambiarDisponibilidadProductoUseCase disponibilidad,
    required EliminarProductoUseCase eliminar,
  })  : _encabezado = encabezado,
        _disponibilidad = disponibilidad,
        _eliminar = eliminar,
        super(const InventarioState()) {
    on<InventarioStarted>(_onStarted);
    on<DisponibilidadEnListaCambiada>(_onDisponibilidad);
    on<ProductoEliminadoDeLista>(_onEliminado);
  }

  Future<void> _onStarted(
    InventarioStarted event,
    Emitter<InventarioState> emit,
  ) async {
    emit(state.copyWith(status: InventarioStatus.loading));
    try {
      final encabezado = await _encabezado();
      emit(state.copyWith(
          status: InventarioStatus.ready, encabezado: encabezado));
    } catch (_) {
      // La lista ya muestra el motivo (por ejemplo, comercio pendiente).
      emit(state.copyWith(status: InventarioStatus.failed));
    }
  }

  Future<void> _onDisponibilidad(
    DisponibilidadEnListaCambiada event,
    Emitter<InventarioState> emit,
  ) async {
    if (state.cambiandoId != null) return;
    emit(state.copyWith(cambiandoId: event.producto.id));
    try {
      final ficha = await _disponibilidad(event.producto.id, event.disponible);
      emit(state.copyWith(
        actualizado: event.producto.copyWith(
          disponible: ficha.precio?.disponible ?? event.disponible,
        ),
      ));
    } on AuthFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: _inesperado));
    }
  }

  Future<void> _onEliminado(
    ProductoEliminadoDeLista event,
    Emitter<InventarioState> emit,
  ) async {
    try {
      await _eliminar(event.producto.id);
      emit(state.copyWith(eliminado: true));
    } on AuthFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: _inesperado));
    }
  }

  static const _inesperado = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
