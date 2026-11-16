/// Nombres de las rutas de la app. Las resuelve `AppRouter`.
abstract final class AppRoutes {
  /// Pantallas 1 y 2 de bienvenida (las desarrolla otra persona del equipo).
  static const onboarding = '/onboarding';

  static const profileSelection = '/profile-selection';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  /// HU-06: guía y condiciones para activar el modo Colaborador.
  static const colaboradorOnboarding = '/colaborador-onboarding';

  /// HU-24: solicitudes pendientes de comercios y repartidores.
  static const adminSolicitudes = '/admin/solicitudes';

  /// HU-24: detalle de una solicitud. Recibe la `Solicitud` como argumento y
  /// devuelve la decisión (`ApprovalStatus`) al cerrarse.
  static const adminSolicitudDetalle = '/admin/solicitudes/detalle';

  /// HU-10: catálogo de productos del comercio (lista paginada).
  static const catalogo = '/comercio/catalogo';

  /// HU-10 + HU-11: Editar producto (datos, foto, stock, precio, historial,
  /// disponibilidad y promoción). Recibe el `Producto` a editar como
  /// argumento (sin argumento crea uno nuevo) y devuelve `true` si cambió algo.
  static const catalogoProducto = '/comercio/catalogo/producto';

  /// HU-10: carga de productos desde un archivo CSV.
  static const catalogoCsv = '/comercio/catalogo/csv';

  /// HU-12: búsqueda de productos del cliente. Recibe opcionalmente el texto
  /// escrito en el Home (`String`).
  static const busqueda = '/cliente/busqueda';

  /// HU-12: un producto con el precio de cada establecimiento. Recibe una
  /// `ConsultaProducto` (por clave de un resultado o por código escaneado).
  static const busquedaDetalle = '/cliente/busqueda/producto';

  /// HU-12: escáner de código de barras. Devuelve el código (`String`).
  static const escaner = '/cliente/escaner';

  /// Ruta con la que arranca la app. Mientras las pantallas 1 y 2 no estén
  /// listas arrancamos en la selección de perfil; cuando existan, basta con
  /// cambiar esta constante por [onboarding].
static const initial = onboarding;
}
