import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';

/// Lo que necesita la pantalla de calificar: qué orden y a quién. Son datos
/// sueltos para que `calificaciones` no dependa de la funcionalidad de órdenes.
class CalificarOrdenArgs {
  final String idOrden;
  final int numeroOrden;

  /// Nombre del comercio de la orden (se muestra en el título).
  final String comercio;
  final TipoCalificacion tipo;

  const CalificarOrdenArgs({
    required this.idOrden,
    required this.numeroOrden,
    required this.comercio,
    required this.tipo,
  });
}
