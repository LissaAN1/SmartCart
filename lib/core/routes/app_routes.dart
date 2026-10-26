/// Nombres de las rutas de la app. Las resuelve `AppRouter`.
abstract final class AppRoutes {
  /// Pantallas 1 y 2 de bienvenida (las desarrolla otra persona del equipo).
  static const onboarding = '/onboarding';

  static const profileSelection = '/profile-selection';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  /// Ruta con la que arranca la app. Mientras las pantallas 1 y 2 no estén
  /// listas arrancamos en la selección de perfil; cuando existan, basta con
  /// cambiar esta constante por [onboarding].
  static const initial = profileSelection;
}
