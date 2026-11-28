import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cart/domain/usecases/get_carrito_usecase.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/orders/domain/compras_reglas.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/domain/repository/compras_repository.dart';

/// HU-20: arma el plan de compra a partir del carrito del cliente: lo divide
/// por comercio, con lo que ofrece cada uno y el precio de hoy. Con el
/// carrito vacío no hay nada que confirmar.
class GetPlanCompraUseCase {
  final GetCarritoUseCase _carrito;
  final ComprasRepository _compras;

  GetPlanCompraUseCase({
    required GetCarritoUseCase carrito,
    required ComprasRepository compras,
  })  : _carrito = carrito,
        _compras = compras;

  Future<PlanCompra> call() async {
    final items = await _carrito();
    if (items.isEmpty) {
      throw const AuthFailure(ComprasReglas.mensajeCarritoVacio);
    }
    final lineas = await _compras.previsualizar([
      for (final item in items)
        LineaSolicitud(idProducto: item.idProducto, cantidad: item.cantidad),
    ]);
    // El carrito se reparte por comercio: de cada uno saldrá una orden.
    return PlanCompra.agrupar(lineas);
  }
}

/// HU-20: confirma la compra. Genera una orden por cada comercio registrado,
/// todas en estado "Orden generada", y entrega la lista de compra de los
/// establecimientos sin registro.
///
/// Comprueba primero las reglas que no necesitan red (carrito vacío, entrega
/// solo donde se ofrece, dirección). La base las vuelve a comprobar y es la
/// que no se puede saltar.
class ConfirmarCompraUseCase {
  final GetClienteActivoUseCase _cliente;
  final ComprasRepository _compras;

  ConfirmarCompraUseCase({
    required GetClienteActivoUseCase cliente,
    required ComprasRepository compras,
  })  : _cliente = cliente,
        _compras = compras;

  Future<ComprobanteCompra> call(
    PlanCompra plan,
    Map<String, EleccionEntrega> elecciones,
  ) async {
    final error = ComprasReglas.validar(plan, elecciones);
    if (error != null) throw AuthFailure(error);
    await _cliente();

    // Los establecimientos sin registro no generan orden: solo su lista.
    final lineas = plan.lineasSolicitud;
    final ordenes = lineas.isEmpty
        ? const <OrdenGenerada>[]
        : await _compras.confirmar(lineas, elecciones);
    return ComprobanteCompra(
      ordenes: ordenes,
      listasDeCompra: plan.sinRegistro,
    );
  }
}

/// HU-20: una página de las órdenes del cliente.
class GetMisOrdenesUseCase {
  final GetClienteActivoUseCase _cliente;
  final ComprasRepository _compras;

  GetMisOrdenesUseCase({
    required GetClienteActivoUseCase cliente,
    required ComprasRepository compras,
  })  : _cliente = cliente,
        _compras = compras;

  Future<PagedResult<Orden>> call(PageRequest request) async {
    await _cliente();
    return _compras.misOrdenes(request);
  }
}
