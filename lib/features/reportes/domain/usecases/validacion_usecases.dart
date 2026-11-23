import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte_por_confirmar.dart';
import 'package:smartcart/features/reportes/domain/repository/validacion_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';

/// HU-15: una página de los reportes de otros colaboradores que esperan
/// confirmación. Exige el modo Colaborador (la base lo vuelve a exigir).
class GetReportesPorConfirmarUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ValidacionRepository _validacion;

  GetReportesPorConfirmarUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ValidacionRepository validacion,
  })  : _colaborador = colaborador,
        _validacion = validacion;

  Future<PagedResult<ReportePorConfirmar>> call(PageRequest request) async {
    await _colaborador();
    return _validacion.porConfirmar(request);
  }
}

/// HU-15: otro colaborador confirma un reporte dudoso. Pide el GPS porque
/// confirmar un precio exige estar en el establecimiento.
class ConfirmarReporteColaboradorUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ObtenerUbicacionUseCase _ubicacion;
  final ValidacionRepository _validacion;

  ConfirmarReporteColaboradorUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ObtenerUbicacionUseCase ubicacion,
    required ValidacionRepository validacion,
  })  : _colaborador = colaborador,
        _ubicacion = ubicacion,
        _validacion = validacion;

  Future<void> call(String idReporte) async {
    await _colaborador();
    final donde = await _ubicacion();
    await _validacion.confirmarComoColaborador(idReporte, donde);
  }
}

/// HU-15: una página de los reportes sobre productos del comercio que esperan
/// que el dueño los confirme o los corrija. Exige un comercio aprobado.
class GetReportesDeMiComercioUseCase {
  final GetComercioAprobadoUseCase _comercio;
  final ValidacionRepository _validacion;

  GetReportesDeMiComercioUseCase({
    required GetComercioAprobadoUseCase comercio,
    required ValidacionRepository validacion,
  })  : _comercio = comercio,
        _validacion = validacion;

  Future<PagedResult<ReportePorConfirmar>> call(PageRequest request) async {
    await _comercio();
    return _validacion.deMiComercio(request);
  }
}

/// HU-15: el comercio confirma el precio que reportó la comunidad.
class ConfirmarReporteComercioUseCase {
  final GetComercioAprobadoUseCase _comercio;
  final ValidacionRepository _validacion;

  ConfirmarReporteComercioUseCase({
    required GetComercioAprobadoUseCase comercio,
    required ValidacionRepository validacion,
  })  : _comercio = comercio,
        _validacion = validacion;

  Future<void> call(String idReporte) async {
    await _comercio();
    await _validacion.confirmarComoComercio(idReporte);
  }
}

/// HU-15: el comercio corrige el precio de un reporte dudoso. El reporte se
/// rechaza (sin penalizar al colaborador) y el precio queda con el valor del
/// comercio.
class CorregirReporteComercioUseCase {
  final GetComercioAprobadoUseCase _comercio;
  final ValidacionRepository _validacion;

  CorregirReporteComercioUseCase({
    required GetComercioAprobadoUseCase comercio,
    required ValidacionRepository validacion,
  })  : _comercio = comercio,
        _validacion = validacion;

  Future<void> call(String idReporte, int precio) async {
    final error = ReporteValidators.precioEnPesos(precio);
    if (error != null) throw AuthFailure('$error.');
    await _comercio();
    await _validacion.corregirComoComercio(idReporte, precio);
  }
}
