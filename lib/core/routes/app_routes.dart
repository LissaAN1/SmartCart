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

  /// HU-14: primer paso del reporte de precio: elegir el establecimiento.
  static const reporteEstablecimiento = '/colaborador/reporte';

  /// HU-14: elegir el producto. Recibe el `EstablecimientoCercano`.
  static const reporteProducto = '/colaborador/reporte/producto';

  /// HU-14: precio, foto y envío. Recibe un `ReporteFormArgs`.
  static const reporteFormulario = '/colaborador/reporte/formulario';

  /// HU-14: sugerir un establecimiento que no está en la plataforma.
  static const reporteSugerir = '/colaborador/reporte/sugerir';

  /// HU-14: historial de reportes del colaborador (lista paginada).
  static const misReportes = '/colaborador/reportes';

  /// HU-15: reportes de otros colaboradores que esperan confirmación.
  static const reportesPorConfirmar = '/colaborador/reportes/por-confirmar';

  /// HU-16: puntos, nivel, reputación e historial de puntos del colaborador.
  static const misPuntos = '/colaborador/puntos';

  /// HU-15: reportes de la comunidad que el comercio confirma o corrige.
  static const reportesComunidad = '/comercio/reportes-comunidad';

  /// HU-14: escáner de códigos de barras. Devuelve el código leído.
  static const reporteEscaner = '/colaborador/reporte/escaner';

  /// HU-17: el carrito del cliente. Recibe un `ClienteBlocs`.
  static const carrito = '/cliente/carrito';

  /// HU-17: favoritos del cliente (productos y comercios). Recibe un
  /// `ClienteBlocs`.
  static const favoritos = '/cliente/favoritos';

  /// HU-17: lista de productos y comercios para agregar al carrito o a
  /// favoritos. Recibe un `ClienteBlocs`.
  static const explorar = '/cliente/explorar';

  /// HU-20: elegir recogida o entrega por comercio y confirmar la compra.
  /// Recibe un `ClienteBlocs` (la compra vacía el carrito).
  static const confirmarCompra = '/cliente/compra';

  /// HU-20: las órdenes del cliente (lista paginada).
  static const misOrdenes = '/cliente/ordenes';

  /// HU-25: calificar al comercio o al repartidor de una orden completada.
  /// Recibe un `CalificarOrdenArgs` y devuelve `true` si se envió.
  static const calificarOrden = '/cliente/ordenes/calificar';

  /// HU-19: ubicación y radio del cliente, con los comercios cercanos en un
  /// mapa.
  static const mapaComercios = '/cliente/mapa';

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
