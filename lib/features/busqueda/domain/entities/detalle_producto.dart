import 'package:smartcart/features/prices/domain/entities/precio.dart';

/// El precio de un producto en un establecimiento (HU-12, escenario 2).
class OfertaProducto {
  final String idProducto;
  final String comercio;
  final String? direccion;
  final String? ciudad;

  /// Precio que paga el cliente hoy: el promocional si está vigente.
  final int precio;

  /// Precio sin promoción.
  final int precioNormal;
  final bool enPromocion;
  final bool disponible;
  final FuentePrecio fuente;
  final DateTime actualizadoEn;

  const OfertaProducto({
    required this.idProducto,
    required this.comercio,
    required this.precio,
    required this.precioNormal,
    required this.actualizadoEn,
    this.direccion,
    this.ciudad,
    this.enPromocion = false,
    this.disponible = true,
    this.fuente = FuentePrecio.comercio,
  });
}

/// Un producto abierto desde la búsqueda o el escáner, con el precio de cada
/// establecimiento: primero los disponibles, del más barato al más caro.
class DetalleProducto {
  final String clave;
  final String nombre;
  final String? marca;
  final String? codigoBarras;
  final String categoria;
  final String? fotoUrl;
  final List<OfertaProducto> ofertas;

  const DetalleProducto({
    required this.clave,
    required this.nombre,
    required this.categoria,
    required this.ofertas,
    this.marca,
    this.codigoBarras,
    this.fotoUrl,
  });

  List<OfertaProducto> get disponibles =>
      [for (final o in ofertas) if (o.disponible) o];

  /// Precio más bajo entre los disponibles, o `null` si está agotado en todos.
  int? get precioMin {
    final lista = disponibles;
    if (lista.isEmpty) return null;
    return lista.map((o) => o.precio).reduce((a, b) => a < b ? a : b);
  }

  int? get precioMax {
    final lista = disponibles;
    if (lista.isEmpty) return null;
    return lista.map((o) => o.precio).reduce((a, b) => a > b ? a : b);
  }
}
