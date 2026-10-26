import 'package:smartcart/core/domain/user_role.dart';

/// Datos de la persona en SmartCart: los de la tabla `usuario` más los
/// perfiles (roles) que tiene asignados en `usuario_rol`.
///
/// El `id` es el mismo de la cuenta de Auth. La contraseña no aparece aquí:
/// solo viaja hasta Supabase Auth.
class Profile {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final Set<UserRole> roles;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roles,
    this.phone,
  });

  bool hasRole(UserRole role) => roles.contains(role);

  @override
  String toString() {
    return 'Profile($id, $email, roles: ${roles.map((r) => r.name).join(',')})';
  }
}
