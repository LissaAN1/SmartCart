import 'package:smartcart/features/auth/domain/entities/profile.dart';

enum ColaboradorOnboardingStatus { initial, loading, success, failure }

/// Estado único del onboarding del colaborador (HU-06).
class ColaboradorOnboardingState {
  final ColaboradorOnboardingStatus status;
  final bool termsAccepted;

  /// Perfil con el rol colaborador ya agregado; solo existe en `success`.
  final Profile? profile;
  final String? errorMessage;

  const ColaboradorOnboardingState({
    this.status = ColaboradorOnboardingStatus.initial,
    this.termsAccepted = false,
    this.profile,
    this.errorMessage,
  });

  /// El mensaje de error no se arrastra: cada estado nuevo parte sin error
  /// salvo que se indique uno.
  ColaboradorOnboardingState copyWith({
    ColaboradorOnboardingStatus? status,
    bool? termsAccepted,
    Profile? profile,
    String? errorMessage,
  }) {
    return ColaboradorOnboardingState(
      status: status ?? this.status,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() => 'ColaboradorOnboardingState(status: ${status.name}, '
      'terms: $termsAccepted, error: $errorMessage)';
}
