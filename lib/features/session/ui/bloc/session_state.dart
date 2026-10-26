import 'package:smartcart/features/auth/domain/entities/profile.dart';

enum SessionStatus { initial, loading, authenticated, unauthenticated, failure }

/// Estado único de la sesión: quién está autenticado, si alguien lo está.
class SessionState {
  final SessionStatus status;
  final Profile? profile;
  final String? errorMessage;

  const SessionState({
    this.status = SessionStatus.initial,
    this.profile,
    this.errorMessage,
  });

  SessionState copyWith({
    SessionStatus? status,
    Profile? profile,
    String? errorMessage,
  }) {
    return SessionState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'SessionState(status: ${status.name}, profile: $profile)';
}
