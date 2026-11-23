import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/puntos/domain/entities/movimiento_puntos.dart';
import 'package:smartcart/features/puntos/domain/repository/puntos_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';

/// Una página del historial de puntos del colaborador, del más reciente al
/// más antiguo.
class GetMovimientosPuntosUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final PuntosRepository _puntos;

  GetMovimientosPuntosUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required PuntosRepository puntos,
  })  : _colaborador = colaborador,
        _puntos = puntos;

  Future<PagedResult<MovimientoPuntos>> call(PageRequest request) async {
    await _colaborador();
    return _puntos.movimientos(request);
  }
}
