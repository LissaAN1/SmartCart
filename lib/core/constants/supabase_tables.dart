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
  static const precioProducto = 'precio_producto';
  static const historialPrecio = 'historial_precio';
  static const promocion = 'promocion';
}

/// Funciones (RPC) de la base. Ver docs/sql/sprint2_hu24.sql.
class SupabaseFunctions {
  const SupabaseFunctions._();

  /// HU-24: aprueba o rechaza una solicitud y notifica al solicitante en una
  /// sola transacción.
  static const decidirSolicitud = 'decidir_solicitud';

  /// HU-11: total de productos, valor del stock y productos con stock bajo
  /// de un comercio. Ver docs/sql/sprint2_hu11.sql.
  static const resumenCatalogo = 'resumen_catalogo';

  /// HU-12: búsqueda del cliente con rango de precios y establecimientos.
  /// Ver docs/sql/sprint2_hu12.sql.
  static const buscarProductos = 'buscar_productos';

  /// HU-12: un producto con el precio de cada establecimiento.
  static const preciosDeProducto = 'precios_de_producto';
}

/// Buckets de Supabase Storage.
class SupabaseBuckets {
  const SupabaseBuckets._();

  /// HU-11: fotos de productos, en la carpeta `<id_comercio>/`.
  static const productos = 'productos';
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
  static const productoStock = 'stock';
  static const productoFotoUrl = 'foto_url';

  // resumen_catalogo() (HU-11)
  static const resumenTotal = 'total_productos';
  static const resumenValorStock = 'valor_stock';
  static const resumenBajoStock = 'bajo_stock';

  // buscar_productos() y precios_de_producto() (HU-12)
  static const busquedaClave = 'clave';
  static const busquedaNombre = 'nombre';
  static const busquedaMarca = 'marca';
  static const busquedaCodigo = 'codigo_barras';
  static const busquedaCategoria = 'categoria';
  static const busquedaFoto = 'foto_url';
  static const busquedaPrecioMin = 'precio_min';
  static const busquedaPrecioMax = 'precio_max';
  static const busquedaEstablecimientos = 'establecimientos';
  static const ofertaProducto = 'id_producto';
  static const ofertaComercio = 'comercio';
  static const ofertaDireccion = 'direccion';
  static const ofertaCiudad = 'ciudad';
  static const ofertaPrecio = 'precio';
  static const ofertaPrecioNormal = 'precio_normal';
  static const ofertaEnPromocion = 'en_promocion';
  static const ofertaDisponible = 'disponible';
  static const ofertaFuente = 'fuente';
  static const ofertaActualizadoEn = 'actualizado_en';

  // categoria (HU-10)
  static const categoriaId = 'id_categoria';
  static const categoriaNombre = 'nombre';

  // precio_producto (HU-11). Ver docs/sql/sprint2_hu11.sql
  static const precioProducto = 'id_producto';
  static const precioValor = 'precio';
  static const precioDisponible = 'disponible';
  static const precioFuente = 'fuente';
  static const precioActualizadoEn = 'actualizado_en';

  // historial_precio (HU-11): lo escribe un trigger, la app solo lo lee
  static const historialId = 'id_historial';
  static const historialProducto = 'id_producto';
  static const historialPrecio = 'precio';
  static const historialDisponible = 'disponible';
  static const historialFuente = 'fuente';
  static const historialRegistradoEn = 'registrado_en';

  // promocion (HU-11): una por producto
  static const promocionId = 'id_promocion';
  static const promocionProducto = 'id_producto';
  static const promocionPrecio = 'precio_promocional';
  static const promocionInicio = 'fecha_inicio';
  static const promocionFin = 'fecha_fin';
  static const promocionActualizadoEn = 'actualizado_en';
}
