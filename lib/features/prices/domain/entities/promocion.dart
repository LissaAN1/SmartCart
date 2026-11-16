import 'package:smartcart/core/utils/format_helpers.dart';

/// En qué momento de su vigencia está una promoción respecto a hoy.
enum EstadoPromocion { programada, vigente, vencida }

/// Lo que el comercio escribe al crear o cambiar una promoción. Las fechas
/// son días completos: la promoción vale desde el inicio hasta el fin,
/// ambos incluidos.
class PromocionDatos {
  final int precioPromocional;
  final DateTime inicio;
  final DateTime fin;

  const PromocionDatos({
    required this.precioPromocional,
    required this.inicio,
    required this.fin,
  });
}

/// Promoción guardada de un producto (hay como máximo una por producto).
class Promocion {
  final String idProducto;
  final int precioPromocional;
  final DateTime inicio;
  final DateTime fin;

  const Promocion({
    required this.idProducto,
    required this.precioPromocional,
    required this.inicio,
    required this.fin,
  });

  EstadoPromocion estadoEn(DateTime ahora) {
    final hoy = soloFecha(ahora);
    if (hoy.isBefore(soloFecha(inicio))) return EstadoPromocion.programada;
    if (hoy.isAfter(soloFecha(fin))) return EstadoPromocion.vencida;
    return EstadoPromocion.vigente;
  }

  /// Escenario 3: una promoción vencida (o que aún no empieza) no se muestra.
  bool vigenteEn(DateTime ahora) => estadoEn(ahora) == EstadoPromocion.vigente;
}
