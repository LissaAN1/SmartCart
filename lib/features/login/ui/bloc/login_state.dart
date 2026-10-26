import 'package:smartcart/features/auth/domain/entities/profile.dart';

enum LoginStatus { initial, loading, success, failure }

/// Estado único de la pantalla de login; status dice en qué momento está.
class LoginState {
  final LoginStatus status;
  final Profile? profile;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.profile,
    this.errorMessage,
  });

  LoginState copyWith({
    LoginStatus? status,
    Profile? profile,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() => 'LoginState(status: ${status.name}, error: $errorMessage)';
}
