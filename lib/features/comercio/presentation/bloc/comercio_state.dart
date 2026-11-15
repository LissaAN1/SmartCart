import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/ubicacion/domain/entities/ubicacion.dart';

enum ComercioStatus {
  initial,
  loading,

  /// Ya se sabe si la cuenta tiene comercio ([ComercioState.comercio]).
  ready,
  saving,
  loadFailed,
  saveFailed,

  /// HU-14: se está leyendo el GPS y guardando la ubicación del comercio.
  locating,
  locationFailed,
}

/// Estado único del comercio del dueño: `comercio == null` con `ready`
/// significa que todavía no lo ha registrado.
class ComercioState {
  final ComercioStatus status;
  final Comercio? comercio;
  final String? errorMessage;

  /// HU-14: ubicación que el dueño tomó en el formulario de registro, antes
  /// de que exista el comercio. Se envía junto con los demás datos.
  final Ubicacion? ubicacion;

  const ComercioState({
    this.status = ComercioStatus.initial,
    this.comercio,
    this.errorMessage,
    this.ubicacion,
  });

  /// El comercio se conserva entre estados (para no perderlo si falla una
  /// recarga); el mensaje de error no se arrastra.
  ComercioState copyWith({
    ComercioStatus? status,
    Comercio? comercio,
    String? errorMessage,
    Ubicacion? ubicacion,
  }) {
    return ComercioState(
      status: status ?? this.status,
      comercio: comercio ?? this.comercio,
      errorMessage: errorMessage,
      ubicacion: ubicacion ?? this.ubicacion,
    );
  }

  @override
  String toString() => 'ComercioState(status: ${status.name}, '
      'comercio: ${comercio?.nombre}, error: $errorMessage)';
}
