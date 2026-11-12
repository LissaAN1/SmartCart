/// Estado de aprobación de un comercio o de un repartidor. Lo cambia solo el
/// administrador (HU-24); al registrarse siempre empiezan en [pendiente].
enum ApprovalStatus {
  pendiente('Pendiente de aprobación'),
  aprobado('Aprobado'),
  rechazado('Rechazado');

  const ApprovalStatus(this.label);

  /// Texto para mostrar al usuario.
  final String label;

  /// Valor guardado en la columna `estado`.
  String get dbName => name;

  /// Devuelve el estado que corresponde a [value] o `null` si no existe.
  static ApprovalStatus? fromDbName(String? value) {
    for (final status in ApprovalStatus.values) {
      if (status.dbName == value) return status;
    }
    return null;
  }
}
