import 'dart:ui';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/geocodificador.dart';

/// Busca direcciones con el geocodificador del teléfono (paquete
/// `geocoding`). Es la única clase que conoce ese paquete. Solo funciona en
/// Android e iOS; en otras plataformas avisa que no está disponible.
class GeocodingGeocodificador implements Geocodificador {
  /// Pedimos los resultados para Colombia: "Calle 5 # 38-20" se escribe así
  /// aquí.
  static const _idioma = Locale('es', 'CO');

  @override
  Future<Ubicacion> buscar(String direccion) async {
    if (geo.GeocodingPlatformFactory.instance == null) {
      throw const AuthFailure(
        'Buscar una dirección no está disponible en este dispositivo.',
      );
    }
    List<geo.Location> resultados;
    try {
      resultados = await geo.Geocoding(locale: _idioma)
          .locationFromAddress(direccion);
    } on Exception {
      // El geocodificador lanza una excepción también cuando no encuentra
      // nada: para la persona es lo mismo.
      resultados = const [];
    }
    if (resultados.isEmpty) {
      throw const AuthFailure(
        'No encontramos esa dirección. Agrega la ciudad o revisa cómo la escribiste.',
      );
    }
    final primero = resultados.first;
    return Ubicacion(latitud: primero.latitude, longitud: primero.longitude);
  }
}
