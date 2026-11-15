import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';

/// HU-10: el comercio aprobado corrige un producto de su catálogo.
class EditarProductoUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final CatalogoRepository _catalogo;

  EditarProductoUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required CatalogoRepository catalogo,
  })  : _comercioAprobado = comercioAprobado,
        _catalogo = catalogo;

  Future<Producto> call(String idProducto, ProductoDatos datos) async {
    final error = ProductoValidators.datos(datos);
    if (error != null) throw AuthFailure(error);
    await _comercioAprobado();
    return _catalogo.editar(idProducto, normalizarProducto(datos));
  }
}
