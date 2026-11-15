import 'dart:math' as math;

/// Un punto en el mapa, en grados.
class Ubicacion {
  final double latitud;
  final double longitud;

  const Ubicacion({required this.latitud, required this.longitud});

  /// Radio medio de la Tierra, en metros.
  static const _radioTierraM = 6371000.0;

  /// Distancia en metros hasta [otra], con la fórmula de haversine. Es la
  /// misma que usa `distancia_metros` en la base (docs/sql/sprint2_hu14.sql),
  /// para que la app y el servidor decidan igual.
  double distanciaA(Ubicacion otra) {
    final dLat = _radianes(otra.latitud - latitud);
    final dLon = _radianes(otra.longitud - longitud);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radianes(latitud)) *
            math.cos(_radianes(otra.latitud)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * _radioTierraM * math.asin(math.min(1.0, math.sqrt(a)));
  }

  static double _radianes(double grados) => grados * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is Ubicacion &&
      other.latitud == latitud &&
      other.longitud == longitud;

  @override
  int get hashCode => Object.hash(latitud, longitud);
}
