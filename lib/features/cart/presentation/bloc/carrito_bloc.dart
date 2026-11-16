import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/core/ui/aviso_ui.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/carrito_reglas.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/cart/domain/usecases/agregar_al_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/cambiar_cantidad_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/get_carrito_usecase.dart';
import 'package:smartcart/features/cart/domain/usecases/quitar_del_carrito_usecase.dart';

abstract class CarritoEvent {}

/// Leer el carrito guardado (al entrar al Home y al reintentar).
class CarritoStarted extends CarritoEvent {}

/// El cliente presionó "Agregar al carrito" en un producto.
class CarritoProductoAgregado extends CarritoEvent {
  final String idProducto;

  CarritoProductoAgregado(this.idProducto);
}

/// El cliente cambió la cantidad de un producto del carrito.
class CarritoCantidadCambiada extends CarritoEvent {
  final String idProducto;
  final int cantidad;

  CarritoCantidadCambiada(this.idProducto, this.cantidad);
}

/// El cliente quitó un producto del carrito.
class CarritoProductoQuitado extends CarritoEvent {
  final String idProducto;

  CarritoProductoQuitado(this.idProducto);
}

enum CarritoStatus { initial, cargando, listo, falloCarga }

class CarritoState {
  final CarritoStatus status;
  final List<ItemCarrito> items;

  /// Error de la carga inicial ([CarritoStatus.falloCarga]).
  final String? errorMessage;

  /// Último mensaje para el cliente (agregado, error al guardar...).
  final AvisoUi? aviso;

  const CarritoState({
    this.status = CarritoStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.aviso,
  });

  /// Cantidad de productos del carrito: lo que muestra el ícono del Home.
  int get productos => items.productos;
  int get unidades => items.unidades;
  bool get vacio => items.isEmpty;

  /// Las líneas se conservan entre estados; el aviso y el error no se
  /// arrastran salvo que se indiquen.
  CarritoState copyWith({
    CarritoStatus? status,
    List<ItemCarrito>? items,
    String? errorMessage,
    AvisoUi? aviso,
  }) {
    return CarritoState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      aviso: aviso,
    );
  }
}

/// El carrito del cliente (HU-17). Lo comparten el Home, la exploración y la
/// pantalla del carrito: viven con una sola instancia, creada por el `RolShell`
/// del cliente.
///
/// Cambiar la cantidad y quitar un producto se muestran al instante (primero
/// se actualiza la pantalla y luego se guarda) para que el carrito responda
/// sin esperar a la red; si guardar falla, se vuelve a lo que dice la base y
/// se avisa.
class CarritoBloc extends Bloc<CarritoEvent, CarritoState> {
  final GetCarritoUseCase _obtener;
  final AgregarAlCarritoUseCase _agregar;
  final CambiarCantidadCarritoUseCase _cambiarCantidad;
  final QuitarDelCarritoUseCase _quitar;

  int _avisos = 0;

  CarritoBloc({
    required GetCarritoUseCase obtener,
    required AgregarAlCarritoUseCase agregar,
    required CambiarCantidadCarritoUseCase cambiarCantidad,
    required QuitarDelCarritoUseCase quitar,
  })  : _obtener = obtener,
        _agregar = agregar,
        _cambiarCantidad = cambiarCantidad,
        _quitar = quitar,
        super(const CarritoState()) {
    on<CarritoStarted>(_onStarted);
    on<CarritoProductoAgregado>(_onAgregado);
    on<CarritoCantidadCambiada>(_onCantidadCambiada);
    on<CarritoProductoQuitado>(_onQuitado);
  }

  AvisoUi _aviso(String texto, {bool esError = false}) =>
      AvisoUi(id: ++_avisos, texto: texto, esError: esError);

  String _mensaje(Object e) =>
      e is AuthFailure ? e.message : 'Ocurrió un error inesperado. Inténtalo de nuevo.';

  Future<void> _onStarted(
    CarritoStarted event,
    Emitter<CarritoState> emit,
  ) async {
    if (state.status == CarritoStatus.cargando) return;
    emit(state.copyWith(status: CarritoStatus.cargando));
    try {
      emit(state.copyWith(
        status: CarritoStatus.listo,
        items: await _obtener(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CarritoStatus.falloCarga,
        errorMessage: _mensaje(e),
      ));
    }
  }

  /// Escenario 1: el producto queda con cantidad 1 (o suma 1 si ya estaba).
  Future<void> _onAgregado(
    CarritoProductoAgregado event,
    Emitter<CarritoState> emit,
  ) async {
    try {
      final cantidad = await _agregar(event.idProducto);
      // Recargamos para traer los datos del producto recién agregado.
      final items = await _obtener();
      final nombre = items
          .where((i) => i.idProducto == event.idProducto)
          .map((i) => i.producto.producto.nombre)
          .firstOrNull;
      final que = nombre == null ? 'El producto' : '"$nombre"';
      emit(state.copyWith(
        status: CarritoStatus.listo,
        items: items,
        aviso: _aviso(
          cantidad == 1
              ? '$que se agregó al carrito'
              : '$que ya estaba en tu carrito: ahora tienes $cantidad',
        ),
      ));
    } catch (e) {
      emit(state.copyWith(aviso: _aviso(_mensaje(e), esError: true)));
    }
  }

  /// Escenario 2: la cantidad cambia y el carrito se actualiza.
  Future<void> _onCantidadCambiada(
    CarritoCantidadCambiada event,
    Emitter<CarritoState> emit,
  ) async {
    final indice =
        state.items.indexWhere((i) => i.idProducto == event.idProducto);
    if (indice < 0 || state.items[indice].cantidad == event.cantidad) return;

    // Una cantidad fuera de rango no se muestra ni se guarda: el caso de uso
    // la rechaza antes de tocar la red y de ahí sale el mensaje.
    if (!CarritoReglas.cantidadValida(event.cantidad)) {
      try {
        await _cambiarCantidad(event.idProducto, event.cantidad);
      } catch (e) {
        emit(state.copyWith(aviso: _aviso(_mensaje(e), esError: true)));
      }
      return;
    }

    final previos = state.items;
    final nuevos = [...previos]
      ..[indice] = previos[indice].conCantidad(event.cantidad);
    emit(state.copyWith(items: nuevos));
    try {
      await _cambiarCantidad(event.idProducto, event.cantidad);
    } catch (e) {
      await _volverALaBase(emit, previos, _mensaje(e));
    }
  }

  Future<void> _onQuitado(
    CarritoProductoQuitado event,
    Emitter<CarritoState> emit,
  ) async {
    final previos = state.items;
    if (!previos.any((i) => i.idProducto == event.idProducto)) return;
    emit(state.copyWith(
      items: previos.where((i) => i.idProducto != event.idProducto).toList(),
    ));
    try {
      await _quitar(event.idProducto);
    } catch (e) {
      await _volverALaBase(emit, previos, _mensaje(e));
    }
  }

  /// Si guardar falló, lo que ve la persona ya no coincide con la base:
  /// volvemos a leerla. Si tampoco se puede leer, dejamos lo que había antes.
  Future<void> _volverALaBase(
    Emitter<CarritoState> emit,
    List<ItemCarrito> previos,
    String mensaje,
  ) async {
    List<ItemCarrito> items;
    try {
      items = await _obtener();
    } catch (_) {
      items = previos;
    }
    emit(state.copyWith(items: items, aviso: _aviso(mensaje, esError: true)));
  }
}
