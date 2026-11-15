import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';
import 'package:smartcart/features/ubicacion/domain/repository/servicio_ubicacion.dart';

/// Lee el GPS con `geolocator`. Es la única clase que conoce ese paquete.
/// Pide el permiso de ubicación si todavía no se ha decidido y traduce cada
/// problema a un mensaje que la persona pueda resolver.
class GeolocatorServicioUbicacion implements ServicioUbicacion {
  /// Tiempo máximo para esperar al GPS: dentro de un local cerrado puede
  /// tardar, pero no queremos dejar la pantalla cargando para siempre.
  static const _espera = Duration(seconds: 20);

  @override
  Future<Ubicacion> actual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AuthFailure(
          'La ubicación del dispositivo está apagada. Actívala e inténtalo de nuevo.',
        );
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        throw const AuthFailure(
          'Necesitamos el permiso de ubicación para comprobar dónde estás.',
        );
      }
      if (permiso == LocationPermission.deniedForever) {
        throw const AuthFailure(
          'El permiso de ubicación está bloqueado. Actívalo en los ajustes de la app.',
        );
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _espera,
        ),
      );
      return Ubicacion(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } on AuthFailure {
      rethrow;
    } on TimeoutException {
      throw const AuthFailure(
        'No pudimos obtener tu ubicación a tiempo. Acércate a una ventana e inténtalo de nuevo.',
      );
    } on Exception {
      throw const AuthFailure(
        'No pudimos conocer tu ubicación. Inténtalo de nuevo.',
      );
    }
  }
}
