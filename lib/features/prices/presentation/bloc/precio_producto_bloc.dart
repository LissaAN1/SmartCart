import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/domain/usecases/actualizar_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/cambiar_disponibilidad_producto_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_promocion_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/quitar_promocion_usecase.dart';

abstract class PrecioProductoEvent {}

/// Al abrir la pantalla (y al reintentar): carga precio, promoción e
/// historial.
class PrecioProductoStarted extends PrecioProductoEvent {}

/// Escenario 1: "Guardar precio".
class PrecioGuardado extends PrecioProductoEvent {
  final int precio;

  PrecioGuardado(this.precio);
}

/// Escenario 2: el interruptor disponible / agotado.
class DisponibilidadCambiada extends PrecioProductoEvent {
  final bool disponible;

  DisponibilidadCambiada(this.disponible);
}

class PromocionGuardada extends PrecioProductoEvent {
  final PromocionDatos datos;

  PromocionGuardada(this.datos);
}

class PromocionQuitada extends PrecioProductoEvent {}

enum PrecioProductoStatus { initial, loading, loadFailed, ready }

/// Qué se está guardando; mientras no sea [ninguna] los botones se
/// deshabilitan.
enum AccionPrecio {
  ninguna,
  guardandoPrecio,
  cambiandoDisponibilidad,
  guardandoPromocion,
  quitandoPromocion,
}

class PrecioProductoState {
  final PrecioProductoStatus status;
  final FichaPrecio ficha;
  final AccionPrecio accion;

  /// Error de la última acción (o de la carga si `status == loadFailed`).
  final String? errorMessage;

  /// Confirmación de la última acción, para mostrarla una vez.
  final String? aviso;

  const PrecioProductoState({
    this.status = PrecioProductoStatus.initial,
    this.ficha = const FichaPrecio(),
    this.accion = AccionPrecio.ninguna,
    this.errorMessage,
    this.aviso,
  });

  bool get ocupado => accion != AccionPrecio.ninguna;

  /// El error y el aviso no se arrastran al siguiente estado.
  PrecioProductoState copyWith({
    PrecioProductoStatus? status,
    FichaPrecio? ficha,
    AccionPrecio? accion,
    String? errorMessage,
    String? aviso,
  }) {
    return PrecioProductoState(
      status: status ?? this.status,
      ficha: ficha ?? this.ficha,
      accion: accion ?? this.accion,
      errorMessage: errorMessage,
      aviso: aviso,
    );
  }
}

/// HU-11: edición rápida del precio, la disponibilidad y la promoción de un
/// producto del catálogo. Después de cada cambio vuelve a leer la ficha para
/// mostrar la fecha y el historial que guardó la base.
class PrecioProductoBloc
    extends Bloc<PrecioProductoEvent, PrecioProductoState> {
  final Producto producto;
  final GetFichaPrecioUseCase _ficha;
  final ActualizarPrecioUseCase _actualizar;
  final CambiarDisponibilidadProductoUseCase _disponibilidad;
  final GuardarPromocionUseCase _guardarPromocion;
  final QuitarPromocionUseCase _quitarPromocion;

  PrecioProductoBloc({
    required this.producto,
    required GetFichaPrecioUseCase ficha,
    required ActualizarPrecioUseCase actualizar,
    required CambiarDisponibilidadProductoUseCase disponibilidad,
    required GuardarPromocionUseCase guardarPromocion,
    required QuitarPromocionUseCase quitarPromocion,
  })  : _ficha = ficha,
        _actualizar = actualizar,
        _disponibilidad = disponibilidad,
        _guardarPromocion = guardarPromocion,
        _quitarPromocion = quitarPromocion,
        super(const PrecioProductoState()) {
    on<PrecioProductoStarted>(_onStarted);
    on<PrecioGuardado>((event, emit) => _ejecutar(
          emit,
          AccionPrecio.guardandoPrecio,
          () => _actualizar(
            producto.id,
            PrecioDatos(
              precio: event.precio,
              disponible: state.ficha.precio?.disponible ?? true,
            ),
          ),
          'Precio actualizado',
        ));
    on<DisponibilidadCambiada>((event, emit) => _ejecutar(
          emit,
          AccionPrecio.cambiandoDisponibilidad,
          () => _disponibilidad(producto.id, event.disponible),
          event.disponible
              ? 'El producto está disponible'
              : 'Marcado como agotado',
        ));
    on<PromocionGuardada>((event, emit) => _ejecutar(
          emit,
          AccionPrecio.guardandoPromocion,
          () => _guardarPromocion(producto.id, event.datos),
          'Promoción guardada',
        ));
    on<PromocionQuitada>((event, emit) => _ejecutar(
          emit,
          AccionPrecio.quitandoPromocion,
          () => _quitarPromocion(producto.id),
          'Promoción eliminada',
        ));
  }

  Future<void> _onStarted(
    PrecioProductoStarted event,
    Emitter<PrecioProductoState> emit,
  ) async {
    emit(state.copyWith(status: PrecioProductoStatus.loading));
    try {
      final ficha = await _ficha(producto.id);
      emit(state.copyWith(status: PrecioProductoStatus.ready, ficha: ficha));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          status: PrecioProductoStatus.loadFailed, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
          status: PrecioProductoStatus.loadFailed, errorMessage: _inesperado));
    }
  }

  /// Corre una acción de escritura y recarga la ficha. Un segundo toque
  /// mientras se guarda no reenvía.
  Future<void> _ejecutar(
    Emitter<PrecioProductoState> emit,
    AccionPrecio accion,
    Future<Object?> Function() escribir,
    String aviso,
  ) async {
    if (state.ocupado || state.status != PrecioProductoStatus.ready) return;
    emit(state.copyWith(accion: accion));
    try {
      await escribir();
      final ficha = await _ficha(producto.id);
      emit(state.copyWith(
        ficha: ficha,
        accion: AccionPrecio.ninguna,
        aviso: aviso,
      ));
    } on AuthFailure catch (e) {
      emit(state.copyWith(
          accion: AccionPrecio.ninguna, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
          accion: AccionPrecio.ninguna, errorMessage: _inesperado));
    }
  }

  static const _inesperado = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
