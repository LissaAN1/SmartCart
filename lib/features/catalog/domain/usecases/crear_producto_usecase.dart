import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';

/// Normaliza los textos del formulario: sin espacios en los bordes y con
/// `null` en lugar de cadena vacía para lo opcional.
ProductoDatos normalizarProducto(ProductoDatos datos) {
  String? opcional(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? null : text;
  }

  return ProductoDatos(
    nombre: datos.nombre.trim(),
    marca: opcional(datos.marca),
    codigoBarras: opcional(datos.codigoBarras),
    idCategoria: datos.idCategoria,
    stock: datos.stock,
  );
}

/// HU-10: el comercio aprobado agrega un producto a su catálogo.
class CrearProductoUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final CatalogoRepository _catalogo;

  CrearProductoUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required CatalogoRepository catalogo,
  })  : _comercioAprobado = comercioAprobado,
        _catalogo = catalogo;

  Future<Producto> call(ProductoDatos datos) async {
    final error = ProductoValidators.datos(datos);
    if (error != null) throw AuthFailure(error);
    final comercio = await _comercioAprobado();
    return _catalogo.crear(comercio.id, normalizarProducto(datos));
  }
}
