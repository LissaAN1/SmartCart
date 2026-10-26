import 'package:smartcart/features/auth/domain/entities/profile.dart';

enum RegisterStatus { initial, loading, success, failure }

/// Estado único de la pantalla de registro; status dice en qué momento está.
class RegisterState {
  final RegisterStatus status;
  final Profile? profile;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.profile,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    Profile? profile,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'RegisterState(status: ${status.name}, error: $errorMessage)';
}
