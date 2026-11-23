import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Contrato de la confirmación de reportes dudosos (HU-15). La revisión
/// automática de cada reporte la hace la base de datos al recibirlo; aquí
/// solo está lo que hacen las personas: confirmar o corregir.
abstract class ValidacionRepository {
  /// Reportes de otros colaboradores que esperan confirmación (los que ya
  /// confirmé no aparecen), del más reciente al más antiguo.
  Future<PagedResult<ReportePorConfirmar>> porConfirmar(PageRequest request);

  /// Reportes sobre productos de mi comercio que esperan que yo los confirme
  /// o los corrija.
  Future<PagedResult<ReportePorConfirmar>> deMiComercio(PageRequest request);

  /// Otro colaborador confirma el reporte. [ubicacion] es donde está: debe
  /// estar en el establecimiento.
  Future<void> confirmarComoColaborador(String idReporte, Ubicacion ubicacion);

  /// El comercio confirma el precio reportado.
  Future<void> confirmarComoComercio(String idReporte);

  /// El comercio corrige: el reporte se rechaza y el precio queda en
  /// [precio] (pesos).
  Future<void> corregirComoComercio(String idReporte, int precio);
}
