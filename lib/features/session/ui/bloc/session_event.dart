/// Algo que se le pide al SessionBloc.
abstract class SessionEvent {}

/// Revisar si hay una sesión guardada en el dispositivo y traer su perfil.
class SessionStarted extends SessionEvent {
  @override
  String toString() => 'SessionStarted()';
}

/// La persona pidió cerrar sesión.
class SignOutRequested extends SessionEvent {
  @override
  String toString() => 'SignOutRequested()';
}
