import 'package:smartcart/core/domain/user_role.dart';

/// Algo que la pantalla de registro le pide al RegisterBloc.
abstract class RegisterEvent {}

/// La persona envió el formulario de registro.
class RegisterSubmitted extends RegisterEvent {
  final String fullName;
  final String email;
  final String? phone;
  final String password;
  final UserRole role;

  RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
  });

  // No incluimos la contraseña para que nunca aparezca en los registros.
  @override
  String toString() => 'RegisterSubmitted(email: $email, role: ${role.name})';
}
