/// Algo que se le pide al SessionBloc.
abstract class SessionEvent {}

/// Revisar si hay una sesión guardada en el dispositivo y traer su perfil.
class SessionStarted extends SessionEvent {
  @override
  String toString() => 'SessionStarted()';
}

/// Volver a leer el perfil de la sesión abierta (por ejemplo, el repartidor
/// que espera su aprobación). A diferencia de [SessionStarted], si falla no
/// da la sesión por perdida: solo avisa.
class SessionRefreshed extends SessionEvent {
  @override
  String toString() => 'SessionRefreshed()';
}

/// La persona pidió cerrar sesión.
class SignOutRequested extends SessionEvent {
  @override
  String toString() => 'SignOutRequested()';
}
