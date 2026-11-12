import 'package:smartcart/core/domain/approval_status.dart';

/// Cómo entrega sus productos el comercio.
enum ServicioComercio {
  recogida('Recogida en tienda'),
  entrega('Entrega a domicilio'),
  ambos('Recogida y entrega');

  const ServicioComercio(this.label);

  final String label;

  /// Valor guardado en la columna `tipo_servicio`.
  String get dbName => name;

  static ServicioComercio? fromDbName(String? value) {
    for (final servicio in ServicioComercio.values) {
      if (servicio.dbName == value) return servicio;
    }
    return null;
  }
}

/// Lo que escribe el dueño en el formulario de registro del comercio. Las
/// horas van como "HH:mm" (24 horas).
class ComercioDatos {
  final String nombre;
  final String telefono;
  final String direccion;
  final String ciudad;
  final String horaApertura;
  final String horaCierre;
  final ServicioComercio servicio;

  const ComercioDatos({
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
    required this.horaApertura,
    required this.horaCierre,
    required this.servicio,
  });
}

/// Comercio ya guardado en la tabla `comercio`.
class Comercio {
  final String id;
  final String nombre;
  final String? telefono;
  final String direccion;
  final String ciudad;
  final String horaApertura;
  final String horaCierre;
  final ServicioComercio servicio;
  final ApprovalStatus estado;

  /// Motivo que escribió el administrador al rechazar el registro (HU-24).
  final String? motivoRechazo;

  const Comercio({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.horaApertura,
    required this.horaCierre,
    required this.servicio,
    required this.estado,
    this.telefono,
    this.motivoRechazo,
  });

  String get horario => '$horaApertura - $horaCierre';
}
