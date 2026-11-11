import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';

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

  /// Puntos, nivel y reputación. Solo si la cuenta tiene el perfil de
  /// Colaborador.
  final CollaboratorStats? collaborator;

  /// Estado de aprobación del repartidor. Solo si la cuenta tiene el perfil
  /// de Repartidor; mientras sea [ApprovalStatus.pendiente] no puede activar
  /// su disponibilidad.
  final ApprovalStatus? courierStatus;

  /// Si el repartidor tiene activada su disponibilidad (`perfil_repartidor`).
  final bool courierAvailable;

  /// Descripción que la persona escribió de sí misma (`usuario.descripcion`).
  final String? description;

  /// Calificación promedio y cuántas calificaciones la forman. Sin
  /// calificaciones, [rating] es `null`.
  final double? rating;
  final int ratingCount;

  /// Fecha de registro de la cuenta (`usuario.fecha_registro`).
  final DateTime? memberSince;
  /// Motivo que escribió el administrador al rechazar al repartidor (HU-24).
  final String? courierRejectionReason;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roles,
    this.phone,
    this.collaborator,
    this.courierStatus,
    this.courierAvailable = false,
    this.description,
    this.rating,
    this.ratingCount = 0,
    this.memberSince,
    this.courierRejectionReason,
  });

  bool hasRole(UserRole role) => roles.contains(role);

  @override
  String toString() {
    return 'Profile($id, $email, roles: ${roles.map((r) => r.name).join(',')})';
  }
}
