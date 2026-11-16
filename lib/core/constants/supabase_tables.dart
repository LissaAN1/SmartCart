/// Nombres de tablas de Supabase usadas en el Sprint 1.
class SupabaseTables {
  const SupabaseTables._();

  static const usuario = 'usuario';
  static const rol = 'rol';
  static const usuarioRol = 'usuario_rol';
  static const perfilColaborador = 'perfil_colaborador';
  static const comercio = 'comercio';
  static const perfilRepartidor = 'perfil_repartidor';
  static const notificacion = 'notificacion';
  static const producto = 'producto';
  static const categoria = 'categoria';
  static const establecimientoSugerido = 'establecimiento_sugerido';

  // HU-17. Ver docs/sql/sprint2_hu17.sql
  static const carritoItem = 'carrito_item';
  static const favoritoProducto = 'favorito_producto';
  static const favoritoComercio = 'favorito_comercio';
}

/// Buckets de Supabase Storage. Ver docs/sql/sprint2_hu14.sql.
class SupabaseBuckets {
  const SupabaseBuckets._();

  /// HU-14: fotos de las etiquetas de precio, en `<id_usuario>/<archivo>`.
  static const reportes = 'reportes';
}

/// Funciones (RPC) de la base. Ver docs/sql/sprint2_hu24.sql.
class SupabaseFunctions {
  const SupabaseFunctions._();

  /// HU-14: guarda el comercio de la cuenta con su latitud y longitud.
  static const fijarUbicacionComercio = 'fijar_ubicacion_comercio';

  /// HU-14: comercios aprobados con ubicación, de menor a mayor distancia.
  static const comerciosCercanos = 'comercios_cercanos';

  /// HU-14: guarda un reporte de precio pendiente si el colaborador está en
  /// el establecimiento.
  static const enviarReportePrecio = 'enviar_reporte_precio';

  /// HU-17: suma un producto al carrito (o su cantidad, si ya está) y
  /// devuelve la cantidad que queda.
  static const agregarAlCarrito = 'agregar_al_carrito';

  /// HU-17: el carrito del cliente, con los datos del producto y del comercio.
  static const miCarrito = 'mi_carrito';

  /// HU-17: favoritos del cliente, del más reciente al más antiguo.
  static const misFavoritosProductos = 'mis_favoritos_productos';
  static const misFavoritosComercios = 'mis_favoritos_comercios';

  /// HU-17: productos y comercios aprobados para que el cliente los explore.
  static const explorarProductos = 'explorar_productos';
  static const explorarComercios = 'explorar_comercios';

  /// HU-14: los reportes del colaborador con sesión iniciada, del más
  /// reciente al más antiguo y de cualquier estado.
  static const misReportes = 'mis_reportes';

  /// HU-24: aprueba o rechaza una solicitud y notifica al solicitante en una
  /// sola transacción.
  static const decidirSolicitud = 'decidir_solicitud';
}

/// Columnas que usa la autenticación. Las confirmamos contra
/// `information_schema.columns` del proyecto de Supabase (octubre de 2026).
class SupabaseColumns {
  const SupabaseColumns._();

  // usuario
  static const usuarioId = 'id_usuario';
  static const usuarioNombre = 'nombre';
  static const usuarioCorreo = 'correo';
  static const usuarioTelefono = 'telefono';
  static const usuarioDescripcion = 'descripcion';
  static const usuarioCalificacion = 'calificacion_promedio';
  static const usuarioTotalCalificaciones = 'total_calificaciones';
  static const usuarioFechaRegistro = 'fecha_registro';

  // rol
  static const rolId = 'id_rol';
  static const rolCodigo = 'codigo';

  // usuario_rol
  static const usuarioRolUsuario = 'id_usuario';
  static const usuarioRolRol = 'id_rol';

  // perfil_colaborador: las políticas exigen estos valores iniciales
  static const colaboradorUsuario = 'id_usuario';
  static const colaboradorPuntos = 'puntos_saldo';
  static const colaboradorNivel = 'nivel';
  static const colaboradorReputacion = 'reputacion';

  // perfil_repartidor (HU-08): la crea el registro con estado 'pendiente'
  static const repartidorUsuario = 'id_usuario';
  static const repartidorEstado = 'estado';
  static const repartidorDisponible = 'disponible';
  static const repartidorCreadoEn = 'creado_en';
  static const repartidorMotivoRechazo = 'motivo_rechazo';

  // comercio (HU-07). Ver docs/sql/sprint2_hu06_07_08.sql
  static const comercioId = 'id_comercio';
  static const comercioUsuario = 'id_usuario';
  static const comercioNombre = 'nombre';
  static const comercioTelefono = 'telefono';
  static const comercioDireccion = 'direccion';
  static const comercioCiudad = 'ciudad';
  static const comercioHoraApertura = 'hora_apertura';
  static const comercioHoraCierre = 'hora_cierre';
  static const comercioServicio = 'tipo_servicio';
  static const comercioEstado = 'estado';
  static const comercioMotivoRechazo = 'motivo_rechazo';
  static const comercioCreadoEn = 'creado_en';

  // notificacion (HU-24). Ver docs/sql/sprint2_hu24.sql
  static const notificacionId = 'id_notificacion';
  static const notificacionUsuario = 'id_usuario';
  static const notificacionTitulo = 'titulo';
  static const notificacionMensaje = 'mensaje';
  static const notificacionLeida = 'leida';
  static const notificacionCreadoEn = 'creado_en';

  // producto (HU-10). Ver docs/sql/sprint2_hu10.sql
  static const productoId = 'id_producto';
  static const productoComercio = 'id_comercio';
  static const productoCategoria = 'id_categoria';
  static const productoNombre = 'nombre';
  static const productoMarca = 'marca';
  static const productoCodigoBarras = 'codigo_barras';
  static const productoCreadoEn = 'creado_en';

  // categoria (HU-10)
  static const categoriaId = 'id_categoria';
  static const categoriaNombre = 'nombre';

  // comercio: ubicación (HU-14). Ver docs/sql/sprint2_hu14.sql
  static const comercioLatitud = 'latitud';
  static const comercioLongitud = 'longitud';

  // Columnas que devuelve comercios_cercanos (HU-14)
  static const cercanoDistancia = 'distancia_m';

  // Columnas que devuelve mis_reportes (HU-14)
  static const misReporteId = 'id_reporte';
  static const misReporteProducto = 'producto';
  static const misReporteComercio = 'comercio';
  static const misReportePrecio = 'precio';
  static const misReportePromocion = 'precio_promocional';
  static const misReporteAgotado = 'agotado';
  static const misReporteEstado = 'estado';
  static const misReporteCreadoEn = 'creado_en';

  // carrito_item y favoritos (HU-17)
  static const carritoUsuario = 'id_usuario';
  static const carritoProducto = 'id_producto';
  static const carritoCantidad = 'cantidad';
  static const favoritoUsuario = 'id_usuario';
  static const favoritoProductoId = 'id_producto';
  static const favoritoComercioId = 'id_comercio';

  // Columnas que devuelven las funciones de HU-17 (producto con comercio)
  static const filaCategoria = 'categoria';
  static const filaComercio = 'comercio';
  static const filaCantidad = 'cantidad';

  // establecimiento_sugerido (HU-14)
  static const sugeridoColaborador = 'id_colaborador';
  static const sugeridoNombre = 'nombre';
  static const sugeridoDireccion = 'direccion';
  static const sugeridoCiudad = 'ciudad';
  static const sugeridoLatitud = 'latitud';
  static const sugeridoLongitud = 'longitud';
}
