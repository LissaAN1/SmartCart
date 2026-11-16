import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';
import 'package:smartcart/features/confianza/domain/repository/reporte_incorrecto_repository.dart';

/// HU-13, escenario 3: el cliente avisa que un precio no es el real y queda
/// un reporte pendiente para su revisión.
///
/// Decidimos dos cosas que el backlog no dice: el motivo es opcional (basta
/// con tocar el botón) y no puede pasar de [motivoMax] caracteres; y quien ya
/// tiene un reporte pendiente del mismo precio no crea otro, para que nadie
/// llene la revisión con el mismo aviso.
class ReportarPrecioIncorrectoUseCase {
  /// Largo máximo del motivo. También lo exige la función SQL.
  static const motivoMax = 300;

  final GetClienteActivoUseCase _cliente;
  final ReporteIncorrectoRepository _reportes;

  ReportarPrecioIncorrectoUseCase({
    required GetClienteActivoUseCase cliente,
    required ReporteIncorrectoRepository reportes,
  })  : _cliente = cliente,
        _reportes = reportes;

  Future<ResultadoReporte> call(String idProducto, {String? motivo}) async {
    if (idProducto.trim().isEmpty) {
      throw const AuthFailure('Elige el precio que quieres reportar.');
    }
    final texto = motivo?.trim();
    if (texto != null && texto.length > motivoMax) {
      throw const AuthFailure(
        'El motivo no puede pasar de $motivoMax caracteres.',
      );
    }
    await _cliente();
    return _reportes.reportar(
      idProducto,
      motivo: texto == null || texto.isEmpty ? null : texto,
    );
  }
}
