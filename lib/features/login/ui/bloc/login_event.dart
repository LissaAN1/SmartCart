import 'package:smartcart/core/domain/user_role.dart';

/// Algo que la pantalla de login le pide al LoginBloc.
abstract class LoginEvent {}

/// La persona envió el formulario de inicio de sesión con el perfil elegido.
class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;
  final UserRole role;

  LoginSubmitted({
    required this.email,
    required this.password,
    required this.role,
  });

  // No incluimos la contraseña para que nunca aparezca en los registros.
  @override
  String toString() => 'LoginSubmitted(email: $email, role: ${role.name})';
}
