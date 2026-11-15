import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/reportes/domain/entities/reporte.dart';
import 'package:smartcart/features/reportes/domain/reporte_reglas.dart';
import 'package:smartcart/features/reportes/domain/repository/reportes_repository.dart';
import 'package:smartcart/features/reportes/domain/usecases/get_colaborador_activo_usecase.dart';
import 'package:smartcart/features/reportes/domain/validators/reporte_validators.dart';
import 'package:smartcart/features/ubicacion/domain/usecases/obtener_ubicacion_usecase.dart';

/// HU-14: el colaborador envía el precio que ve en un establecimiento.
///
/// Orden de las comprobaciones: primero lo que no necesita red ni GPS (precio
/// y foto), luego que sea colaborador, y al final dónde está. Así, un reporte
/// sin foto se rechaza al instante sin pedir el GPS. El reporte queda
/// pendiente; validarlo es de la HU-15.
///
/// La distancia se comprueba aquí para avisar rápido, y otra vez en
/// `enviar_reporte_precio`, que es la que no se puede saltar.
class EnviarReportePrecioUseCase {
  final GetColaboradorActivoUseCase _colaborador;
  final ReportesRepository _reportes;
  final ObtenerUbicacionUseCase _ubicacion;

  EnviarReportePrecioUseCase({
    required GetColaboradorActivoUseCase colaborador,
    required ReportesRepository reportes,
    required ObtenerUbicacionUseCase ubicacion,
  })  : _colaborador = colaborador,
        _reportes = reportes,
        _ubicacion = ubicacion;

  /// Devuelve el id del reporte guardado.
  Future<String> call(ReporteDatos datos, FotoReporte? foto) async {
    final promo = datos.precioPromocional;
    final error = ReporteValidators.precioEnPesos(datos.precio) ??
        (promo == null
            ? null
            : ReporteValidators.promocionEnPesos(promo, datos.precio)) ??
        ReporteValidators.foto(foto);
    if (error != null) throw AuthFailure('$error.');

    final userId = await _colaborador();
    final donde = await _ubicacion();

    final distancia = donde.distanciaA(datos.establecimiento.ubicacion);
    if (!ReporteReglas.estaDentro(distancia)) {
      throw AuthFailure(ReporteReglas.mensajeFuera(distancia));
    }

    return _reportes.enviarReporte(userId, datos, foto!, donde);
  }
}
