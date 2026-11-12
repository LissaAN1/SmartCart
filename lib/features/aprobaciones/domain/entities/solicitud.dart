import 'package:smartcart/features/comercio/domain/entities/comercio.dart';

/// Qué se está aprobando: un comercio (HU-07) o un repartidor (HU-08).
enum TipoSolicitud {
  comercio('Comercio', 'Comercios'),
  repartidor('Repartidor', 'Repartidores');

  const TipoSolicitud(this.label, this.plural);

  final String label;
  final String plural;

  /// Valor que recibe la función `decidir_solicitud` en `p_tipo`.
  String get dbName => name;
}

/// Una solicitud pendiente de aprobación que revisa el administrador
/// (HU-24).
class Solicitud {
  final TipoSolicitud tipo;

  /// `id_comercio` para un comercio; `id_usuario` para un repartidor.
  final String id;

  /// Cuenta que hizo la solicitud: a ella le llega la notificación.
  final String idUsuario;

  /// Nombre del comercio o del repartidor.
  final String nombre;

  /// Nombre de la persona dueña de la cuenta (para un comercio, el dueño).
  final String? responsable;
  final String? correo;
  final String? telefono;
  final DateTime? creadoEn;

  /// Datos del establecimiento. Solo en las solicitudes de comercio.
  final Comercio? comercio;

  const Solicitud({
    required this.tipo,
    required this.id,
    required this.idUsuario,
    required this.nombre,
    this.responsable,
    this.correo,
    this.telefono,
    this.creadoEn,
    this.comercio,
  });

  @override
  String toString() => 'Solicitud(${tipo.name}, $id, $nombre)';
}
