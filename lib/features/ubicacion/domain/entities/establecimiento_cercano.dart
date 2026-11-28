import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Un comercio aprobado que ya guardó su ubicación, con la distancia hasta
/// quien lo buscó. Lo usan el colaborador para elegir dónde reportar (HU-14)
/// y el cliente para ver los comercios de su radio (HU-19).
class EstablecimientoCercano {
  final String id;
  final String nombre;
  final String direccion;
  final String ciudad;
  final Ubicacion ubicacion;

  /// Distancia en metros desde el punto de búsqueda.
  final double distanciaM;

  const EstablecimientoCercano({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.ubicacion,
    required this.distanciaM,
  });
}
