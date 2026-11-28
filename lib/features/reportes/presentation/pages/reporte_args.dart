import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';

export 'package:smartcart/features/ubicacion/presentation/formato_distancia.dart';

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
