import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Una página de los establecimientos cercanos donde el colaborador puede
/// reportar un precio, del más cerca al más lejos.
class GetEstablecimientosCercanosUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ReportesRepository _reportes;

  GetEstablecimientosCercanosUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ReportesRepository reportes,
  })  : _colaborador = colaborador,
        _reportes = reportes;

  Future<PagedResult<EstablecimientoCercano>> call(
    Ubicacion ubicacion,
    PageRequest request,
  ) async {
    await _colaborador();
    return _reportes.establecimientosCercanos(ubicacion, request);
  }
}
