import 'package:smartcart/features/puntos/domain/entities/resumen_puntos.dart';
import 'package:smartcart/features/puntos/domain/repository/puntos_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';

/// Lee los puntos, el nivel y la reputación del colaborador. Exige el modo
/// Colaborador activo; la base lo vuelve a exigir.
class GetResumenPuntosUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final PuntosRepository _puntos;

  GetResumenPuntosUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required PuntosRepository puntos,
  })  : _colaborador = colaborador,
        _puntos = puntos;

  Future<ResumenPuntos> call() async {
    await _colaborador();
    return _puntos.resumen();
  }
}
