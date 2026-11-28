import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';

abstract class CalificacionesRepository {
  /// Guarda la calificación de la orden y devuelve el nuevo promedio de
  /// quien la recibió. La base rechaza lo que no cumple las reglas (orden no
  /// completada, no es el cliente, ya calificada).
  Future<ResumenCalificaciones> calificar({
    required String idOrden,
    required TipoCalificacion tipo,
    required int estrellas,
    String? comentario,
  });
}
