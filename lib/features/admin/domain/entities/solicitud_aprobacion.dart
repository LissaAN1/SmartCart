/// Qué se está pidiendo aprobar.
enum TipoSolicitud {
  comercio('Comercio'),
  repartidor('Repartidor');

  const TipoSolicitud(this.label);

  final String label;

  /// Valor que usan las funciones de Supabase (`tipo`).
  String get dbName => name;

  static TipoSolicitud? fromDbName(String? value) {
    for (final tipo in TipoSolicitud.values) {
      if (tipo.dbName == value) return tipo;
    }
    return null;
  }
}

/// Solicitud pendiente de un comercio o de un repartidor (HU-24).
class SolicitudAprobacion {
  final TipoSolicitud tipo;

  /// `id_comercio` (comercio) o `id_usuario` (repartidor).
  final String id;

  /// Cuenta que hizo la solicitud: a ella le llega la notificación.
  final String userId;

  /// Nombre del comercio o de la persona repartidora.
  final String nombre;

  /// Dirección del comercio o correo del repartidor.
  final String detalle;
  final String? contacto;

  const SolicitudAprobacion({
    required this.tipo,
    required this.id,
    required this.userId,
    required this.nombre,
    required this.detalle,
    this.contacto,
  });
}
