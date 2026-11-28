import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// El precio de un producto del carrito en un comercio aprobado: el mismo
/// producto que tiene el cliente, aunque sea de otro comercio (HU-12).
class OfertaComparable {
  final String idProducto;
  final String idComercio;
  final String comercio;
  final String direccion;
  final String ciudad;

  /// `null` si el comercio no guardó su ubicación (HU-14).
  final Ubicacion? ubicacionComercio;

  /// Precio que se paga hoy: el de la promoción si está vigente.
  final int precio;
  final int precioNormal;
  final bool enPromocion;
  final bool disponible;
  final FuentePrecio fuente;
  final DateTime actualizadoEn;

  /// Calificación promedio del comercio (HU-25); `null` si no tiene.
  final double? calificacion;
  final int totalCalificaciones;

  const OfertaComparable({
    required this.idProducto,
    required this.idComercio,
    required this.comercio,
    required this.precio,
    required this.precioNormal,
    required this.actualizadoEn,
    this.direccion = '',
    this.ciudad = '',
    this.ubicacionComercio,
    this.enPromocion = false,
    this.disponible = true,
    this.fuente = FuentePrecio.comercio,
    this.calificacion,
    this.totalCalificaciones = 0,
  });

  bool get tieneCalificaciones =>
      calificacion != null && totalCalificaciones > 0;
}

/// Un producto del carrito con todas sus ofertas publicadas (también las
/// agotadas). [idProducto] es el producto que el cliente agregó.
class LineaComparable {
  final String idProducto;
  final String nombre;
  final String? marca;
  final int cantidad;
  final List<OfertaComparable> ofertas;

  const LineaComparable({
    required this.idProducto,
    required this.nombre,
    required this.cantidad,
    required this.ofertas,
    this.marca,
  });

  /// La oferta del producto que el cliente agregó (la de su comercio), o
  /// `null` si ese producto no tiene precio publicado.
  OfertaComparable? get ofertaActual {
    for (final o in ofertas) {
      if (o.idProducto == idProducto) return o;
    }
    return null;
  }

  /// Precio vigente del producto del carrito; `null` si no tiene precio o
  /// está agotado.
  int? get precioActual {
    final oferta = ofertaActual;
    return oferta != null && oferta.disponible ? oferta.precio : null;
  }
}
