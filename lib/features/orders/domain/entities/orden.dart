import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';

/// Una orden de la lista "Mis órdenes" del cliente.
class Orden {
  final String id;

  /// Número corto para nombrarla ("Orden #1043").
  final int numero;
  final String comercio;
  final EstadoOrden estado;
  final TipoEntrega tipoEntrega;

  /// Total en pesos (COP).
  final int total;
  final DateTime creadoEn;

  /// La entrega ya tiene repartidor asignado (HU-22).
  final bool tieneRepartidor;

  /// Si el cliente ya calificó al comercio y al repartidor (HU-25).
  final bool calificadaComercio;
  final bool calificadaRepartidor;

  /// HU-23: último cambio de estado (si se sabe).
  final DateTime? actualizadoEn;

  /// HU-23: cuándo el cliente confirmó la recogida o la recepción; `null`
  /// mientras no la confirme.
  final DateTime? cerradaEn;

  /// HU-23: unidades compradas en esta orden.
  final int productos;

  const Orden({
    required this.id,
    required this.numero,
    required this.comercio,
    required this.estado,
    required this.tipoEntrega,
    required this.total,
    required this.creadoEn,
    this.tieneRepartidor = false,
    this.calificadaComercio = false,
    this.calificadaRepartidor = false,
    this.actualizadoEn,
    this.cerradaEn,
    this.productos = 0,
  });

  /// Solo una orden completada se califica, y una sola vez.
  bool get puedeCalificarComercio => estado.completada && !calificadaComercio;

  /// Al repartidor se le califica si la orden tuvo uno.
  bool get puedeCalificarRepartidor =>
      estado.completada && tieneRepartidor && !calificadaRepartidor;
}

/// Una orden recién generada al confirmar la compra.
class OrdenGenerada {
  final String id;
  final int numero;
  final String idComercio;
  final String comercio;
  final TipoEntrega tipoEntrega;
  final int total;

  /// La lista de compra de este comercio.
  final List<LineaCompra> lineas;

  /// Siempre [EstadoOrden.generada]: así nacen todas.
  EstadoOrden get estado => EstadoOrden.generada;

  const OrdenGenerada({
    required this.id,
    required this.numero,
    required this.idComercio,
    required this.comercio,
    required this.tipoEntrega,
    required this.total,
    this.lineas = const [],
  });

  OrdenGenerada conLineas(List<LineaCompra> lineas) => OrdenGenerada(
        id: id,
        numero: numero,
        idComercio: idComercio,
        comercio: comercio,
        tipoEntrega: tipoEntrega,
        total: total,
        lineas: lineas,
      );
}

/// Lo que recibe el cliente al confirmar: las órdenes que se generaron (una
/// por comercio registrado) y la lista de compra de cada establecimiento sin
/// registro.
class ComprobanteCompra {
  final List<OrdenGenerada> ordenes;
  final List<GrupoCompra> listasDeCompra;

  const ComprobanteCompra({
    required this.ordenes,
    this.listasDeCompra = const [],
  });

  int get total => ordenes.fold(0, (suma, o) => suma + o.total);
}
