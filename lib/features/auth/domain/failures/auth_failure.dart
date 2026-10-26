/// Error esperado del flujo de autenticación con un mensaje que ya se puede
/// mostrar. La capa de datos traduce las excepciones de Supabase a esta clase
/// para que ni los casos de uso ni la interfaz conozcan el SDK.
class AuthFailure implements Exception {
  final String message;

  const AuthFailure(this.message);

  @override
  String toString() => message;
}
