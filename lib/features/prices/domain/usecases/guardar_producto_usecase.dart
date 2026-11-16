import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/usecases/actualizar_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';

/// HU-10 + HU-11: "Guardar cambios" de la pantalla Editar producto. En un
/// solo paso crea o edita el producto (HU-10), sube la foto si se eligió una
/// y guarda el precio si cambió (HU-11).
///
/// Valida todo antes de escribir, así un precio inválido no deja el producto
/// guardado a medias.
class GuardarProductoUseCase {
  final CrearProductoUseCase _crear;
  final EditarProductoUseCase _editar;
  final ActualizarPrecioUseCase _actualizarPrecio;
  final GetComercioAprobadoUseCase _comercioAprobado;
  final CatalogoRepository _catalogo;

  GuardarProductoUseCase({
    required CrearProductoUseCase crear,
    required EditarProductoUseCase editar,
    required ActualizarPrecioUseCase actualizarPrecio,
    required GetComercioAprobadoUseCase comercioAprobado,
    required CatalogoRepository catalogo,
  })  : _crear = crear,
        _editar = editar,
        _actualizarPrecio = actualizarPrecio,
        _comercioAprobado = comercioAprobado,
        _catalogo = catalogo;

  /// [editando] es `null` al crear. [precio] es `null` si se dejó vacío.
  Future<Producto> call({
    Producto? editando,
    required ProductoDatos datos,
    int? precio,
    ImagenProducto? foto,
  }) async {
    final error = ProductoValidators.datos(datos) ??
        (precio == null ? null : PrecioValidators.valor(precio));
    if (error != null) throw AuthFailure(error);

    var producto = editando == null
        ? await _crear(datos)
        : await _editar(editando.id, datos);

    if (foto != null) {
      final comercio = await _comercioAprobado();
      producto = await _catalogo.subirFoto(comercio.id, producto, foto);
    } else if (editando?.fotoUrl != null) {
      producto = producto.copyWith(fotoUrl: editando!.fotoUrl);
    }

    final disponible = editando?.disponible ?? true;
    if (precio != null && precio != editando?.precio) {
      await _actualizarPrecio(
        producto.id,
        PrecioDatos(precio: precio, disponible: disponible),
      );
      return producto.copyWith(precio: precio, disponible: disponible);
    }
    final anterior = editando?.precio;
    return anterior == null
        ? producto
        : producto.copyWith(precio: anterior, disponible: disponible);
  }
}
