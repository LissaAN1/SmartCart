import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/busqueda/domain/entities/detalle_producto.dart';
import 'package:smartcart/features/busqueda/domain/repository/busqueda_repository.dart';
import 'package:smartcart/features/catalog/domain/validators/producto_validators.dart';

/// Qué producto abrir: el de un resultado de la búsqueda o el de un código
/// de barras escaneado.
sealed class ConsultaProducto {
  const ConsultaProducto();
}

class ConsultaPorClave extends ConsultaProducto {
  final String clave;

  const ConsultaPorClave(this.clave);
}

class ConsultaPorCodigo extends ConsultaProducto {
  final String codigo;

  const ConsultaPorCodigo(this.codigo);
}

/// HU-12 · escenario 2: abre un producto con el precio de cada
/// establecimiento, desde un resultado o escaneando su código de barras.
class GetDetalleProductoUseCase {
  final AuthRepository _auth;
  final BusquedaRepository _busqueda;

  GetDetalleProductoUseCase({
    required AuthRepository auth,
    required BusquedaRepository busqueda,
  })  : _auth = auth,
        _busqueda = busqueda;

  Future<DetalleProducto> call(ConsultaProducto consulta) async {
    if (_auth.currentUser() == null) {
      throw const AuthFailure('Inicia sesión para ver los precios.');
    }
    final clave = switch (consulta) {
      ConsultaPorClave(:final clave) => clave,
      ConsultaPorCodigo(:final codigo) => _claveDeCodigo(codigo),
    };
    final detalle = await _busqueda.detalle(clave);
    if (detalle == null || detalle.ofertas.isEmpty) {
      throw AuthFailure(switch (consulta) {
        ConsultaPorCodigo(:final codigo) =>
          'No encontramos productos con el código $codigo.',
        ConsultaPorClave() => 'Este producto ya no está publicado.',
      });
    }
    return detalle;
  }

  /// La misma clave que arma la base (`clave_producto`) para un código.
  static String _claveDeCodigo(String codigo) {
    final limpio = codigo.trim();
    final error = ProductoValidators.codigoBarras(limpio);
    if (limpio.isEmpty || error != null) {
      throw const AuthFailure(
        'Ese código no es válido. Debe tener entre 8 y 14 dígitos.',
      );
    }
    return 'cb:$limpio';
  }
}
