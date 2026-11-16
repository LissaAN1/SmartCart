import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';

/// Una página de los productos de un establecimiento, filtrados por nombre,
/// marca o código de barras. El código escaneado se busca igual que un texto
/// pero con coincidencia exacta.
class BuscarProductosReporteUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ReportesRepository _reportes;

  BuscarProductosReporteUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ReportesRepository reportes,
  })  : _colaborador = colaborador,
        _reportes = reportes;

  Future<PagedResult<Producto>> call(
    String idComercio,
    ConsultaProductoReporte consulta,
    PageRequest request,
  ) async {
    await _colaborador();
    return _reportes.buscarProductos(
      idComercio,
      ConsultaProductoReporte(texto: consulta.texto.trim(), esCodigo: consulta.esCodigo),
      request,
    );
  }
}
