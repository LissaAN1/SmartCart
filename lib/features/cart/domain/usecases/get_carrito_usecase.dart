import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';

/// Lee el carrito guardado del cliente. Es lo que hace que el carrito se
/// recupere al volver a abrir la app.
class GetCarritoUseCase {
  final GetClienteActivoUseCase _cliente;
  final CarritoRepository _carrito;

  GetCarritoUseCase({
    required GetClienteActivoUseCase cliente,
    required CarritoRepository carrito,
  })  : _cliente = cliente,
        _carrito = carrito;

  Future<List<ItemCarrito>> call() async {
    await _cliente();
    return _carrito.obtener();
  }
}
