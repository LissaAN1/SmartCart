import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';

/// Lo que recibe la pantalla del formulario del reporte: el establecimiento
/// y el producto que el colaborador ya eligió.
class ReporteFormArgs {
  final EstablecimientoCercano establecimiento;
  final Producto producto;

  const ReporteFormArgs({
    required this.establecimiento,
    required this.producto,
  });
}

/// "85 m" o "1,2 km", para mostrar qué tan lejos queda un establecimiento.
String formatoDistancia(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
