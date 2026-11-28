import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

/// Dónde está el cliente y hasta qué distancia quiere comprar (HU-19). Se
/// guarda en su cuenta y la comparación del carrito (HU-18) la usa para
/// calcular las distancias.
class PreferenciaUbicacion {
  final Ubicacion ubicacion;
  final int radioM;

  /// La dirección que escribió el cliente; `null` si la ubicación vino del
  /// GPS.
  final String? direccion;

  const PreferenciaUbicacion({
    required this.ubicacion,
    required this.radioM,
    this.direccion,
  });

  bool get desdeGps => direccion == null;

  PreferenciaUbicacion conRadio(int radioM) => PreferenciaUbicacion(
        ubicacion: ubicacion,
        radioM: radioM,
        direccion: direccion,
      );

  @override
  bool operator ==(Object other) =>
      other is PreferenciaUbicacion &&
      other.ubicacion == ubicacion &&
      other.radioM == radioM &&
      other.direccion == direccion;

  @override
  int get hashCode => Object.hash(ubicacion, radioM, direccion);
}
