import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/carrito_reglas.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';

/// HU-17, escenario 2: el cliente cambia la cantidad de un producto del
/// carrito. La cantidad va de 1 a 99; para sacar un producto existe
/// [QuitarDelCarritoUseCase], así que bajar de 1 no lo borra en silencio.
class CambiarCantidadCarritoUseCase {
  final GetClienteActivoUseCase _cliente;
  final CarritoRepository _carrito;

  CambiarCantidadCarritoUseCase({
    required GetClienteActivoUseCase cliente,
    required CarritoRepository carrito,
  })  : _cliente = cliente,
        _carrito = carrito;

  Future<void> call(String idProducto, int cantidad) async {
    if (cantidad < CarritoReglas.cantidadMin) {
      throw const AuthFailure(
        'La cantidad mínima es 1. Para sacar el producto usa "Quitar".',
      );
    }
    if (cantidad > CarritoReglas.cantidadMax) {
      throw const AuthFailure(
        'El máximo es de ${CarritoReglas.cantidadMax} unidades por producto.',
      );
    }
    await _cliente();
    await _carrito.cambiarCantidad(idProducto, cantidad);
  }
}
