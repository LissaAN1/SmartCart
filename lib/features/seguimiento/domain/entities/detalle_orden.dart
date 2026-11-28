import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';

/// Un producto de la orden, con el precio que tenía al comprar.
class ItemOrden {
  final String nombre;
  final String? marca;
  final int cantidad;
  final int precioUnitario;

  const ItemOrden({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    this.marca,
  });

  int get subtotal => cantidad * precioUnitario;
}

/// Un paso ya ocurrido en la línea de tiempo "Estado del pedido".
class CambioEstado {
  final EstadoOrden estado;
  final DateTime fecha;

  const CambioEstado({required this.estado, required this.fecha});
}

/// HU-23: el detalle de una orden del cliente: la tienda, los productos y
/// cómo ha avanzado.
class DetalleOrden {
  final Orden orden;
  final String? comercioDireccion;
  final String? comercioCiudad;
  final double? comercioLatitud;
  final double? comercioLongitud;

  /// Destino de la entrega a domicilio; `null` en una recogida.
  final String? direccionEntrega;
  final List<ItemOrden> items;

  /// Del más antiguo al más reciente.
  final List<CambioEstado> historial;

  const DetalleOrden({
    required this.orden,
    this.comercioDireccion,
    this.comercioCiudad,
    this.comercioLatitud,
    this.comercioLongitud,
    this.direccionEntrega,
    this.items = const [],
    this.historial = const [],
  });

  int get unidades => items.fold(0, (suma, i) => suma + i.cantidad);

  /// Hora del último cambio de estado, para "Actualizado ...".
  DateTime get actualizadoEn =>
      historial.isEmpty ? orden.creadoEn : historial.last.fecha;
}
