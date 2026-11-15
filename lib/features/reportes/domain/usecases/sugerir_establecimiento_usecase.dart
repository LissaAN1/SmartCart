import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';

/// HU-14: el colaborador sugiere un establecimiento que todavía no está en
/// la plataforma. Se guarda con la ubicación donde está en ese momento, que
/// le sirve a quien lo revise para ubicarlo.
class SugerirEstablecimientoUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ReportesRepository _reportes;
  final ObtenerUbicacionUseCase _ubicacion;

  SugerirEstablecimientoUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ReportesRepository reportes,
    required ObtenerUbicacionUseCase ubicacion,
  })  : _colaborador = colaborador,
        _reportes = reportes,
        _ubicacion = ubicacion;

  Future<void> call(SugerenciaDatos datos) async {
    final error = ReporteValidators.sugerencia(datos);
    if (error != null) throw AuthFailure(error);

    final userId = await _colaborador();
    final donde = await _ubicacion();
    await _reportes.sugerirEstablecimiento(
      userId,
      SugerenciaDatos(
        nombre: datos.nombre.trim(),
        direccion: datos.direccion.trim(),
        ciudad: datos.ciudad.trim(),
      ),
      donde,
    );
  }
}
