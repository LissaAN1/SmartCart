/// Algo que se le pide al SessionBloc.
abstract class SessionEvent {}

/// Revisar si hay una sesión guardada en el dispositivo y traer su perfil.
class SessionStarted extends SessionEvent {
  @override
  String toString() => 'SessionStarted()';
}

/// Volver a leer el perfil de la sesión actual, por ejemplo para saber si el
/// administrador ya aprobó al repartidor. A diferencia de [SessionStarted],
/// un error de red no cierra la sesión: solo muestra un aviso.
class ProfileRefreshRequested extends SessionEvent {
  @override
  String toString() => 'ProfileRefreshRequested()';
}

/// La persona pidió cerrar sesión.
class SignOutRequested extends SessionEvent {
  @override
  String toString() => 'SignOutRequested()';
}
