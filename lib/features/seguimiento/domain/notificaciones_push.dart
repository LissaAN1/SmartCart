/// Un aviso push que llegó con la app abierta.
class AvisoPush {
  final String titulo;
  final String mensaje;

  const AvisoPush({required this.titulo, required this.mensaje});
}

/// HU-23: contrato de las notificaciones push del teléfono. El dominio no
/// sabe que detrás está Firebase: lo resuelve la capa de datos.
abstract class NotificacionesPush {
  /// Pide permiso para notificar y devuelve el token del teléfono, o `null`
  /// si no se puede (permiso negado o Firebase sin configurar). Nunca falla:
  /// la app sigue funcionando con los avisos dentro de la app.
  Future<String?> activar();

  /// "android", "ios" o "web".
  String get plataforma;

  /// Firebase cambia el token de vez en cuando: hay que volver a guardarlo.
  Stream<String> get tokenRenovado;

  /// Avisos que llegan mientras la app está abierta (Firebase no los muestra
  /// solo en ese caso).
  Stream<AvisoPush> get enPrimerPlano;

  /// La persona tocó un aviso de la barra del sistema.
  Stream<void> get avisoAbierto;
}
