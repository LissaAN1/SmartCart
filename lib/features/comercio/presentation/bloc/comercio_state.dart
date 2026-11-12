import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

enum ComercioStatus {
  initial,
  loading,

  /// Ya se sabe si la cuenta tiene comercio ([ComercioState.comercio]).
  ready,
  saving,
  loadFailed,
  saveFailed,
}

/// Estado único del comercio del dueño: `comercio == null` con `ready`
/// significa que todavía no lo ha registrado.
class ComercioState {
  final ComercioStatus status;
  final Comercio? comercio;
  final String? errorMessage;

  const ComercioState({
    this.status = ComercioStatus.initial,
    this.comercio,
    this.errorMessage,
  });

  /// El comercio se conserva entre estados (para no perderlo si falla una
  /// recarga); el mensaje de error no se arrastra.
  ComercioState copyWith({
    ComercioStatus? status,
    Comercio? comercio,
    String? errorMessage,
  }) {
    return ComercioState(
      status: status ?? this.status,
      comercio: comercio ?? this.comercio,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() => 'ComercioState(status: ${status.name}, '
      'comercio: ${comercio?.nombre}, error: $errorMessage)';
}
