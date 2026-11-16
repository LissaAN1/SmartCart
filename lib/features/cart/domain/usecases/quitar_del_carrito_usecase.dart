import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';

/// HU-17: el cliente quita un producto del carrito.
class QuitarDelCarritoUseCase {
  final GetClienteActivoUseCase _cliente;
  final CarritoRepository _carrito;

  QuitarDelCarritoUseCase({
    required GetClienteActivoUseCase cliente,
    required CarritoRepository carrito,
  })  : _cliente = cliente,
        _carrito = carrito;

  Future<void> call(String idProducto) async {
    await _cliente();
    await _carrito.quitar(idProducto);
  }
}
