/// Algo que la pantalla de onboarding le pide al ColaboradorOnboardingBloc.
abstract class ColaboradorOnboardingEvent {}

/// La persona marcó o desmarcó "Acepto las condiciones de uso".
class TermsToggled extends ColaboradorOnboardingEvent {
  final bool accepted;

  TermsToggled(this.accepted);

  @override
  String toString() => 'TermsToggled($accepted)';
}

/// La persona presionó "Activar".
class ActivationSubmitted extends ColaboradorOnboardingEvent {
  @override
  String toString() => 'ActivationSubmitted()';
}
