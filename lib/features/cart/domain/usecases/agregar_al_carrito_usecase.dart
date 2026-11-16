import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';

/// HU-17, escenario 1: el cliente agrega un producto y queda con cantidad 1.
///
/// Mantenemos una sola referencia por producto: si ya estaba en el carrito
/// no se crea otra línea, se le suma 1 a la cantidad. Devuelve la cantidad
/// que quedó, para que la pantalla pueda decir "ahora tienes 2".
class AgregarAlCarritoUseCase {
  final GetClienteActivoUseCase _cliente;
  final CarritoRepository _carrito;

  AgregarAlCarritoUseCase({
    required GetClienteActivoUseCase cliente,
    required CarritoRepository carrito,
  })  : _cliente = cliente,
        _carrito = carrito;

  Future<int> call(String idProducto) async {
    if (idProducto.trim().isEmpty) {
      throw const AuthFailure('Elige un producto para agregarlo al carrito.');
    }
    await _cliente();
    return _carrito.agregar(idProducto);
  }
}
