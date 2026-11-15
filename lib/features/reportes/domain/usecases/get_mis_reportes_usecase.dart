import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/reportes/domain/entities/mi_reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';

/// Una página del historial de reportes del colaborador, del más reciente al
/// más antiguo. Incluye los reportes en cualquier estado: uno recién enviado
/// aparece como pendiente aunque nadie lo haya revisado todavía.
class GetMisReportesUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ReportesRepository _reportes;

  GetMisReportesUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ReportesRepository reportes,
  })  : _colaborador = colaborador,
        _reportes = reportes;

  Future<PagedResult<MiReporte>> call(PageRequest request) async {
    await _colaborador();
    return _reportes.misReportes(request);
  }
}
