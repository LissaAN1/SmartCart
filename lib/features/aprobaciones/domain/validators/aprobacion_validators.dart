/// Reglas de la decisión del administrador (HU-24). Las usan el caso de uso
/// y el diálogo de rechazo, así el mensaje es el mismo en los dos lados.
abstract final class AprobacionValidators {
  static const motivoMinimo = 10;
  static const motivoMaximo = 300;

  /// Al rechazar el motivo es obligatorio: el solicitante lo recibe en su
  /// notificación y tiene que poder entender qué corregir.
  static String? motivoRechazo(String? value) {
    final motivo = value?.trim() ?? '';
    if (motivo.isEmpty) return 'Escribe el motivo del rechazo.';
    if (motivo.length < motivoMinimo) {
      return 'Explica el motivo con al menos $motivoMinimo caracteres.';
    }
    if (motivo.length > motivoMaximo) {
      return 'El motivo no puede superar $motivoMaximo caracteres.';
    }
    return null;
  }
}
