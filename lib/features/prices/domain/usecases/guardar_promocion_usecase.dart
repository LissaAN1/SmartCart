import 'package:smartcart/core/utils/format_helpers.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/prices/domain/entities/ficha_precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/validators/precio_validators.dart';

/// HU-11: crea la promoción de un producto o reemplaza la que tenía. El
/// precio promocional debe ser menor que el precio normal actual. Devuelve la
/// ficha ya actualizada.
class GuardarPromocionUseCase {
  final GetComercioAprobadoUseCase _comercioAprobado;
  final PreciosRepository _precios;
  final DateTime Function() _ahora;

  GuardarPromocionUseCase({
    required GetComercioAprobadoUseCase comercioAprobado,
    required PreciosRepository precios,
    DateTime Function()? ahora,
  })  : _comercioAprobado = comercioAprobado,
        _precios = precios,
        _ahora = ahora ?? DateTime.now;

  Future<FichaPrecio> call(String idProducto, PromocionDatos datos) async {
    final errorFechas =
        PrecioValidators.fechas(datos.inicio, datos.fin, _ahora());
    if (errorFechas != null) throw AuthFailure(errorFechas);
    await _comercioAprobado();
    final normal = await _precios.precio(idProducto);
    if (normal == null) {
      throw const AuthFailure(
        'Registra el precio normal del producto antes de crear una promoción.',
      );
    }
    final errorPrecio = PrecioValidators.valorPromocional(
      datos.precioPromocional,
      normal.precio,
    );
    if (errorPrecio != null) throw AuthFailure(errorPrecio);
    await _precios.guardarPromocion(
      idProducto,
      PromocionDatos(
        precioPromocional: datos.precioPromocional,
        inicio: soloFecha(datos.inicio),
        fin: soloFecha(datos.fin),
      ),
    );
    return leerFichaPrecio(_precios, idProducto);
  }
}
