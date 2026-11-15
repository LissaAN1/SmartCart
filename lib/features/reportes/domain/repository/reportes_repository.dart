import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Contrato de los reportes de precio de los colaboradores (HU-14).
abstract class ReportesRepository {
  /// Los establecimientos cercanos a [ubicacion], del más cerca al más lejos.
  Future<PagedResult<EstablecimientoCercano>> establecimientosCercanos(
    Ubicacion ubicacion,
    PageRequest request,
  );

  /// Productos del establecimiento [idComercio] que coinciden con
  /// [consulta]. Con texto vacío devuelve todos.
  Future<PagedResult<Producto>> buscarProductos(
    String idComercio,
    ConsultaProducto consulta,
    PageRequest request,
  );

  /// Sube la foto y guarda el reporte con estado pendiente. Devuelve el id
  /// del reporte. [ubicacion] es donde estaba [userId] al enviarlo.
  Future<String> enviarReporte(
    String userId,
    ReporteDatos datos,
    FotoReporte foto,
    Ubicacion ubicacion,
  );

  /// Los reportes de la cuenta con sesión iniciada, del más reciente al más
  /// antiguo y de cualquier estado.
  Future<PagedResult<MiReporte>> misReportes(PageRequest request);

  /// Guarda la sugerencia de un establecimiento nuevo, con [ubicacion] como
  /// el lugar donde estaba [userId].
  Future<void> sugerirEstablecimiento(
    String userId,
    SugerenciaDatos datos,
    Ubicacion ubicacion,
  );
}
