import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';

/// HU-11 · escenario 1: el comercio cambia el precio de un producto. La base
/// guarda la fecha, la hora y la fuente "Comercio", y conserva el historial.
class ActualizarPrecioUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final PreciosRepository _precios;

  ActualizarPrecioUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required PreciosRepository precios,
  })  : _comercioAprobado = comercioAprobado,
        _precios = precios;

  Future<PrecioProducto> call(String idProducto, PrecioDatos datos) async {
    final error = PrecioValidators.valor(datos.precio);
    if (error != null) throw AuthFailure(error);
    await _comercioAprobado();
    return _precios.guardarPrecio(idProducto, datos);
  }
}
