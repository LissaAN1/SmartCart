import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';

/// Contrato de las compras y órdenes del cliente (HU-20). Los precios y las
/// reglas de la compra las pone la base de datos; la app solo manda qué
/// productos y cuántas unidades, y cómo se quiere recibir cada orden.
abstract class ComprasRepository {
  /// Cada producto de [lineas] con su comercio, lo que el comercio ofrece y
  /// el precio de hoy. Repartirlas por comercio es de `PlanCompra.agrupar`.
  Future<List<LineaPrevia>> previsualizar(List<LineaSolicitud> lineas);

  /// Genera la compra: una orden por cada comercio, todas en estado
  /// "Orden generada", y saca lo comprado del carrito. [elecciones] va por id
  /// de comercio.
  Future<List<OrdenGenerada>> confirmar(
    List<LineaSolicitud> lineas,
    Map<String, EleccionEntrega> elecciones,
  );

  /// Las órdenes del cliente con sesión iniciada, de la más reciente a la más
  /// antigua.
  Future<PagedResult<Orden>> misOrdenes(PageRequest request);
}
