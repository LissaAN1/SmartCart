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

  // HU-11. Ver docs/sql/sprint2_hu11.sql
  static const precioProducto = 'precio_producto';
  static const historialPrecio = 'historial_precio';
  static const promocion = 'promocion';

  // HU-17. Ver docs/sql/sprint2_hu17.sql
  static const carritoItem = 'carrito_item';
  static const favoritoProducto = 'favorito_producto';
  static const favoritoComercio = 'favorito_comercio';

  // HU-13. Ver docs/sql/sprint2_hu13.sql
  static const reportePrecioIncorrecto = 'reporte_precio_incorrecto';

  // HU-19. Ver docs/sql/sprint3_hu19.sql
  static const ubicacionCliente = 'ubicacion_cliente';
}

/// Funciones (RPC) de la base. Ver docs/sql/sprint2_hu24.sql.
class SupabaseFunctions {
  const SupabaseFunctions._();

  /// HU-14: guarda el comercio de la cuenta con su latitud y longitud.
  static const fijarUbicacionComercio = 'fijar_ubicacion_comercio';

  /// HU-14: comercios aprobados con ubicación, de menor a mayor distancia.
  static const comerciosCercanos = 'comercios_cercanos';

  /// HU-19: guarda la ubicación y el radio del cliente, y los comercios
  /// aprobados dentro de ese radio. Ver docs/sql/sprint3_hu19.sql.
  static const guardarUbicacionCliente = 'guardar_ubicacion_cliente';
  static const comerciosEnRadio = 'comercios_en_radio';

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

  /// HU-08: el repartidor aprobado cambia su disponibilidad (en línea o no).
  /// Ver docs/sql/perfiles_reales.sql.
  static const cambiarDisponibilidad = 'cambiar_disponibilidad';

  /// HU-13: guarda un reporte pendiente del precio vigente de un producto.
  /// Devuelve `registrado` o `ya_reportado`.
  static const reportarPrecioIncorrecto = 'reportar_precio_incorrecto';

  /// HU-14: los reportes del colaborador con sesión iniciada, del más
  /// reciente al más antiguo y de cualquier estado.
  static const misReportes = 'mis_reportes';

  /// HU-15: reportes de otros colaboradores que esperan una confirmación, los
  /// de mi comercio que espera confirmar o corregir, y las tres acciones.
  /// Ver docs/sql/sprint3_hu15_hu16.sql.
  static const reportesPorConfirmar = 'reportes_por_confirmar';
  static const reportesDeMiComercio = 'reportes_de_mi_comercio';
  static const confirmarReporteColaborador = 'confirmar_reporte_colaborador';
  static const confirmarReporteComercio = 'confirmar_reporte_comercio';
  static const corregirReporteComercio = 'corregir_reporte_comercio';

  /// HU-16: puntos, nivel y reputación del colaborador, y su historial de
  /// puntos del más reciente al más antiguo.
  static const resumenPuntos = 'resumen_puntos';
  static const misMovimientosPuntos = 'mis_movimientos_puntos';

  /// HU-20: la vista previa de la compra (cada producto con su comercio y el
  /// precio de hoy), la confirmación (una orden por comercio) y las órdenes
  /// del cliente. Ver docs/sql/sprint3_hu20_hu25.sql.
  static const previsualizarCompra = 'previsualizar_compra';
  static const confirmarCompra = 'confirmar_compra';
  static const misOrdenes = 'mis_ordenes';

  /// HU-25: califica al comercio o al repartidor de una orden completada y
  /// devuelve su promedio y su total de calificaciones.
  static const calificarOrden = 'calificar_orden';

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

/// Buckets de Supabase Storage. Ver docs/sql/sprint2_hu11.sql y
/// docs/sql/sprint2_hu14.sql.
class SupabaseBuckets {
  const SupabaseBuckets._();

  /// HU-11: fotos de productos, en la carpeta `<id_comercio>/`.
  static const productos = 'productos';

  /// HU-14: fotos de las etiquetas de precio, en `<id_usuario>/<archivo>`.
  static const reportes = 'reportes';
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

  // comercio: ubicación (HU-14). Ver docs/sql/sprint2_hu14.sql
  static const comercioLatitud = 'latitud';
  static const comercioLongitud = 'longitud';

  // Columnas que devuelven comercios_cercanos (HU-14) y comercios_en_radio
  // (HU-19)
  static const cercanoDistancia = 'distancia_m';

  // ubicacion_cliente (HU-19)
  static const ubicacionClienteLatitud = 'latitud';
  static const ubicacionClienteLongitud = 'longitud';
  static const ubicacionClienteDireccion = 'direccion';
  static const ubicacionClienteRadio = 'radio_m';

  // Columnas que devuelve mis_reportes (HU-14)
  static const misReporteId = 'id_reporte';
  static const misReporteProducto = 'producto';
  static const misReporteComercio = 'comercio';
  static const misReportePrecio = 'precio';
  static const misReportePromocion = 'precio_promocional';
  static const misReporteAgotado = 'agotado';
  static const misReporteEstado = 'estado';
  static const misReporteCreadoEn = 'creado_en';
  // ...y desde la HU-15
  static const misReporteMotivo = 'motivo';
  static const misReporteRequiereConfirmacion = 'requiere_confirmacion';

  // Columnas que devuelven reportes_por_confirmar y reportes_de_mi_comercio
  // (HU-15). El id, el producto, el comercio, el precio, la fecha y el motivo
  // se llaman como en mis_reportes.
  static const porConfirmarPrecioActual = 'precio_actual';

  // Columnas que devuelven resumen_puntos y mis_movimientos_puntos (HU-16)
  static const resumenSaldo = 'puntos_saldo';
  static const resumenAcumulados = 'puntos_acumulados';
  static const resumenNivel = 'nivel';
  static const resumenReputacion = 'reputacion';
  static const movimientoId = 'id_movimiento';
  static const movimientoPuntos = 'puntos';
  static const movimientoTipo = 'tipo';
  static const movimientoMotivo = 'motivo';
  static const movimientoCreadoEn = 'creado_en';

  // Columnas que devuelve previsualizar_compra (HU-20)
  static const lineaProducto = 'id_producto';
  static const lineaNombre = 'nombre';
  static const lineaMarca = 'marca';
  static const lineaCantidad = 'cantidad';
  static const lineaComercioId = 'id_comercio';
  static const lineaComercio = 'comercio';
  static const lineaServicio = 'tipo_servicio';
  static const lineaPrecio = 'precio';
  static const lineaDisponible = 'disponible';

  // Columnas que devuelve confirmar_compra (HU-20)
  static const compraOrdenId = 'id_orden';
  static const compraOrdenNumero = 'numero';
  static const compraComercioId = 'id_comercio';
  static const compraComercio = 'comercio';
  static const compraTipoEntrega = 'tipo_entrega';
  static const compraTotal = 'total';

  // Columnas que devuelve mis_ordenes (HU-20 y HU-25)
  static const ordenId = 'id_orden';
  static const ordenNumero = 'numero';
  static const ordenComercio = 'comercio';
  static const ordenEstado = 'estado';
  static const ordenTipoEntrega = 'tipo_entrega';
  static const ordenTotal = 'total';
  static const ordenCreadoEn = 'creado_en';
  static const ordenTieneRepartidor = 'tiene_repartidor';
  static const ordenCalificadaComercio = 'calificada_comercio';
  static const ordenCalificadaRepartidor = 'calificada_repartidor';

  // Columnas que devuelve calificar_orden (HU-25)
  static const calificacionPromedio = 'promedio';
  static const calificacionTotal = 'total';

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
