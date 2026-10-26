/// Los cinco perfiles de SmartCart.
///
/// Vive en `core` porque lo comparten la selección de perfil, el login, el
/// registro y la navegación. No depende de Flutter ni de Supabase: la parte
/// visual de cada perfil está en `PerfilVisual`.
enum UserRole {
  cliente('Cliente'),
  colaborador('Colaborador'),
  comercio('Comercio'),
  repartidor('Repartidor'),
  administrador('Administrador');

  const UserRole(this.label);

  /// Nombre para mostrar al usuario.
  final String label;

  /// Valor de la columna `rol.codigo`. La política `usuario_rol_insert_own`
  /// de Supabase compara contra 'administrador', así que el nombre del enum
  /// tiene que coincidir con ese código.
  String get dbName => name;

  /// El README indica que el administrador se asigna a mano en Supabase y no
  /// se puede auto-asignar desde la app, así que el registro lo excluye.
  bool get canSelfRegister => this != UserRole.administrador;

  /// Devuelve el perfil que corresponde a [value] o `null` si no existe.
  static UserRole? fromDbName(String? value) {
    for (final role in UserRole.values) {
      if (role.dbName == value) return role;
    }
    return null;
  }
}
