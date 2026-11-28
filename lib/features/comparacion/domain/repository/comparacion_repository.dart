import 'package:smartcart/features/comparacion/domain/entities/linea_comparable.dart';

/// Contrato de la comparación del carrito (HU-18).
abstract class ComparacionRepository {
  /// Cada producto del carrito del cliente con todas las ofertas publicadas
  /// del mismo producto en comercios aprobados, con el precio vigente al
  /// momento de pedirlas.
  Future<List<LineaComparable>> ofertasDelCarrito();
}
