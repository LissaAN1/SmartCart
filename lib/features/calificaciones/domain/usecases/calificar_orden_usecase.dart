import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/calificaciones/domain/calificacion_reglas.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/domain/repository/calificaciones_repository.dart';
import 'package:smartcart/features/cliente/domain/usecases/get_cliente_activo_usecase.dart';

/// HU-25: el cliente califica al comercio o al repartidor de una orden
/// completada (1 a 5 estrellas y un comentario opcional).
///
/// Valida el rango antes de tocar la red. Que la orden esté completada, que
/// sea del cliente y que no se haya calificado ya lo decide la base.
class CalificarOrdenUseCase {
  final GetClienteActivoUseCase _cliente;
  final CalificacionesRepository _calificaciones;

  CalificarOrdenUseCase({
    required GetClienteActivoUseCase cliente,
    required CalificacionesRepository calificaciones,
  })  : _cliente = cliente,
        _calificaciones = calificaciones;

  Future<ResumenCalificaciones> call({
    required String idOrden,
    required TipoCalificacion tipo,
    required int estrellas,
    String? comentario,
  }) async {
    final error = CalificacionReglas.validar(estrellas, comentario);
    if (error != null) throw AuthFailure(error);
    await _cliente();
    return _calificaciones.calificar(
      idOrden: idOrden,
      tipo: tipo,
      estrellas: estrellas,
      comentario: CalificacionReglas.limpiarComentario(comentario),
    );
  }
}
