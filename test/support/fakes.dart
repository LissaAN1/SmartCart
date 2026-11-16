import 'dart:async';

import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/get_solicitudes_pendientes_usecase.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/get_notificaciones_no_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/domain/usecases/marcar_notificaciones_leidas_usecase.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/catalog/domain/entities/categoria.dart';
import 'package:smartcart/features/catalog/domain/entities/filtro_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/imagen_producto.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/entities/resumen_catalogo.dart';
import 'package:smartcart/features/catalog/domain/entities/resultado_carga_csv.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_imagen.dart';
import 'package:smartcart/features/catalog/domain/usecases/cargar_productos_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_archivo_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/elegir_foto_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_categorias_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_encabezado_catalogo_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_formulario_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_productos_usecase.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/catalogo_lista_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/prices/domain/entities/precio.dart';
import 'package:smartcart/features/prices/domain/entities/promocion.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/usecases/actualizar_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/cambiar_disponibilidad_producto_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_producto_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_promocion_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/quitar_promocion_usecase.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/repartidor/presentation/bloc/disponibilidad_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';

/// Repositorio de autenticación en memoria para las pruebas.
class FakeAuthRepository implements AuthRepository {
  AppUser? current;
  Object? signInError;
  Object? signUpError;

  /// Si se asigna, signIn/signUp esperan a que se complete (simula la red).
  Completer<void>? gate;

  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;

  @override
  Future<AppUser> signUp({required String email, required String password}) async {
    signUpCalls++;
    await gate?.future;
    if (signUpError != null) throw signUpError!;
    current = AppUser(id: 'u1', email: email);
    return current!;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    signInCalls++;
    await gate?.future;
    if (signInError != null) throw signInError!;
    current = AppUser(id: 'u1', email: email);
    return current!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    current = null;
  }

  @override
  AppUser? currentUser() => current;
}

/// Repositorio de perfiles en memoria para las pruebas.
class FakeProfileRepository implements ProfileRepository {
  Profile? stored;
  Object? createError;
  Object? getError;
  Object? activateError;
  final created = <Profile>[];
  final collaboratorIds = <String>[];
  final courierIds = <String>[];
  int activateCalls = 0;
  Object? availabilityError;
  final availabilityCalls = <bool>[];

  @override
  Future<void> createProfile(Profile profile) async {
    if (createError != null) throw createError!;
    created.add(profile);
    stored = profile;
  }

  @override
  Future<void> createCollaboratorProfile(String userId) async {
    collaboratorIds.add(userId);
  }

  @override
  Future<void> createCourierProfile(String userId) async {
    courierIds.add(userId);
  }

  @override
  Future<void> activateCollaboratorMode(String userId) async {
    activateCalls++;
    if (activateError != null) throw activateError!;
    final current = stored!;
    stored = Profile(
      id: current.id,
      fullName: current.fullName,
      email: current.email,
      phone: current.phone,
      roles: {...current.roles, UserRole.colaborador},
      collaborator: CollaboratorStats.initial,
      courierStatus: current.courierStatus,
    );
  }

  @override
  Future<void> setCourierAvailability(bool available) async {
    if (availabilityError != null) throw availabilityError!;
    availabilityCalls.add(available);
  }

  @override
  Future<Profile> getProfile(String id) async {
    if (getError != null) throw getError!;
    return stored ??
        (throw const AuthFailure(
          'Tu cuenta no tiene un perfil registrado en SmartCart.',
        ));
  }
}

Profile profileWith(
  Set<UserRole> roles, {
  CollaboratorStats? collaborator,
  ApprovalStatus? courierStatus,
  bool courierAvailable = false,
  double? rating,
  int ratingCount = 0,
  DateTime? memberSince,
  String? courierRejectionReason,
}) =>
    Profile(
      id: 'u1',
      fullName: 'Ana María Gómez',
      email: 'ana@correo.com',
      phone: '+57 300 000 0000',
      roles: roles,
      collaborator: collaborator,
      courierStatus: courierStatus,
      courierAvailable: courierAvailable,
      rating: rating,
      ratingCount: ratingCount,
      memberSince: memberSince,
      courierRejectionReason: courierRejectionReason,
    );

/// Repositorio de comercios en memoria para las pruebas.
class FakeComercioRepository implements ComercioRepository {
  Comercio? stored;
  Object? getError;
  Object? registerError;
  int registerCalls = 0;

  @override
  Future<Comercio?> getMine(String userId) async {
    if (getError != null) throw getError!;
    return stored;
  }

  @override
  Future<Comercio> register(String userId, ComercioDatos datos) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    stored = Comercio(
      id: 'c1',
      nombre: datos.nombre,
      telefono: datos.telefono,
      direccion: datos.direccion,
      ciudad: datos.ciudad,
      horaApertura: datos.horaApertura,
      horaCierre: datos.horaCierre,
      servicio: datos.servicio,
      estado: ApprovalStatus.pendiente,
    );
    return stored!;
  }
}

/// Datos válidos del formulario de registro del comercio.
const comercioDatosValidos = ComercioDatos(
  nombre: 'Minimercado La Esquina',
  telefono: '+57 300 000 0000',
  direccion: 'Calle 10 # 5-20',
  ciudad: 'Cali, San Fernando',
  horaApertura: '07:00',
  horaCierre: '20:00',
  servicio: ServicioComercio.ambos,
);

/// Un comercio ya guardado con el [estado] indicado.
Comercio comercioConEstado(ApprovalStatus estado, {String? motivoRechazo}) =>
    Comercio(
      id: 'c1',
      nombre: 'Minimercado La Esquina',
      telefono: '+57 300 000 0000',
      direccion: 'Calle 10 # 5-20',
      ciudad: 'Cali, San Fernando',
      horaApertura: '07:00',
      horaCierre: '20:00',
      servicio: ServicioComercio.ambos,
      estado: estado,
      motivoRechazo: motivoRechazo,
    );

/// Una decisión que recibió [FakeSolicitudesRepository.decidir].
typedef DecisionRegistrada = ({Solicitud solicitud, bool aprobar, String? motivo});

/// Solicitudes pendientes en memoria (HU-24). Decidir una la quita de la
/// lista, como pasa en la base cuando deja de estar pendiente.
class FakeSolicitudesRepository implements SolicitudesRepository {
  final pendientesPorTipo = <TipoSolicitud, List<Solicitud>>{
    TipoSolicitud.comercio: [],
    TipoSolicitud.repartidor: [],
  };
  final decisiones = <DecisionRegistrada>[];
  final pedidos = <(TipoSolicitud, PageRequest)>[];
  Object? listError;
  Object? decidirError;

  @override
  Future<PagedResult<Solicitud>> pendientes(
    TipoSolicitud tipo,
    PageRequest request,
  ) async {
    pedidos.add((tipo, request));
    if (listError != null) throw listError!;
    final todas = pendientesPorTipo[tipo]!;
    // Igual que `range(from, to)`: el `to` es inclusivo.
    final filas = todas.skip(request.from).take(request.pageSize + 1).toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<void> decidir(
    Solicitud solicitud, {
    required bool aprobar,
    String? motivo,
  }) async {
    if (decidirError != null) throw decidirError!;
    decisiones.add((solicitud: solicitud, aprobar: aprobar, motivo: motivo));
    pendientesPorTipo[solicitud.tipo]!.removeWhere((s) => s.id == solicitud.id);
  }
}

/// Notificaciones en memoria.
class FakeNotificacionRepository implements NotificacionRepository {
  final noLeidasList = <Notificacion>[];
  final marcadas = <String>[];
  Object? getError;

  @override
  Future<List<Notificacion>> noLeidas(String userId) async {
    if (getError != null) throw getError!;
    return List.of(noLeidasList);
  }

  @override
  Future<void> marcarLeidas(List<String> ids) async {
    marcadas.addAll(ids);
    noLeidasList.removeWhere((n) => ids.contains(n.id));
  }
}

/// Solicitud pendiente de un comercio.
Solicitud solicitudComercio({String id = 'c1', String nombre = 'Minimercado La Esquina'}) =>
    Solicitud(
      tipo: TipoSolicitud.comercio,
      id: id,
      idUsuario: 'dueno-$id',
      nombre: nombre,
      responsable: 'Pedro Pérez',
      correo: 'pedro@correo.com',
      telefono: '+57 300 000 0000',
      creadoEn: DateTime(2026, 11, 2),
      comercio: comercioConEstado(ApprovalStatus.pendiente),
    );

/// Solicitud pendiente de un repartidor.
Solicitud solicitudRepartidor({String id = 'r1', String nombre = 'Luis Torres'}) =>
    Solicitud(
      tipo: TipoSolicitud.repartidor,
      id: id,
      idUsuario: id,
      nombre: nombre,
      responsable: nombre,
      correo: 'luis@correo.com',
      creadoEn: DateTime(2026, 11, 3),
    );

/// Las categorías que trae la base (docs/sql/sprint2_hu10.sql).
const categoriasDePrueba = [
  Categoria(id: 'cat-super', nombre: 'Super'),
  Categoria(id: 'cat-frutas', nombre: 'Frutas'),
  Categoria(id: 'cat-lacteos', nombre: 'Lácteos'),
];

/// Catálogo en memoria (HU-10): los productos se guardan por comercio, como
/// las políticas RLS que solo dejan ver los del propio comercio.
class FakeCatalogoRepository implements CatalogoRepository {
  final productosPorComercio = <String, List<Producto>>{};
  final creados = <({String idComercio, ProductoDatos datos})>[];
  final consultasDeCodigos = <List<String>>[];
  Object? listError;
  Object? categoriasError;
  Object? crearError;
  Object? editarError;
  Object? eliminarError;
  Object? crearVariosError;
  int crearVariosCalls = 0;
  int _secuencia = 0;

  List<Producto> deComercio(String idComercio) =>
      productosPorComercio.putIfAbsent(idComercio, () => []);

  Producto _armar(ProductoDatos datos, {String? id}) => Producto(
        id: id ?? 'p${++_secuencia}',
        nombre: datos.nombre,
        marca: datos.marca,
        codigoBarras: datos.codigoBarras,
        idCategoria: datos.idCategoria,
        stock: datos.stock,
        categoria: categoriasDePrueba
            .firstWhere((c) => c.id == datos.idCategoria,
                orElse: () => const Categoria(id: '', nombre: ''))
            .nombre,
      );

  /// Agrega productos ya guardados, sin pasar por los casos de uso.
  void precargar(String idComercio, int cuantos) {
    for (var i = 1; i <= cuantos; i++) {
      deComercio(idComercio).add(_armar(ProductoDatos(
        nombre: 'Producto $i',
        idCategoria: 'cat-super',
        codigoBarras: '77000000${i.toString().padLeft(4, '0')}',
      )));
    }
  }

  /// Filtros con los que se pidió cada página (HU-11).
  final filtrosPedidos = <FiltroCatalogo>[];
  Object? resumenError;
  Object? fotoError;
  final fotosSubidas = <({String idComercio, String idProducto})>[];

  @override
  Future<PagedResult<Producto>> productos(
    String idComercio,
    PageRequest request, {
    FiltroCatalogo filtro = const FiltroCatalogo(),
  }) async {
    if (listError != null) throw listError!;
    filtrosPedidos.add(filtro);
    final texto = filtro.texto.trim().toLowerCase();
    final filas = deComercio(idComercio)
        .where((p) =>
            filtro.idCategoria == null || p.idCategoria == filtro.idCategoria)
        .where((p) =>
            texto.isEmpty ||
            p.nombre.toLowerCase().contains(texto) ||
            (p.marca ?? '').toLowerCase().contains(texto))
        .skip(request.from)
        .take(request.pageSize + 1)
        .toList();
    return PagedResult.fromRows(filas, request);
  }

  @override
  Future<ResumenCatalogo> resumen(String idComercio) async {
    if (resumenError != null) throw resumenError!;
    final productos = deComercio(idComercio);
    return ResumenCatalogo(
      totalProductos: productos.length,
      valorStock: productos.fold(
          0, (suma, p) => suma + (p.precio ?? 0) * p.stock),
      bajoStock: productos.where((p) => p.stockBajo).length,
    );
  }

  @override
  Future<Producto> subirFoto(
    String idComercio,
    Producto producto,
    ImagenProducto foto,
  ) async {
    if (fotoError != null) throw fotoError!;
    fotosSubidas.add((idComercio: idComercio, idProducto: producto.id));
    final conFoto = producto.copyWith(
        fotoUrl: 'https://fotos.test/$idComercio/${producto.id}.${foto.extension}');
    _reemplazar(conFoto);
    return conFoto;
  }

  void _reemplazar(Producto producto) {
    for (final lista in productosPorComercio.values) {
      final i = lista.indexWhere((p) => p.id == producto.id);
      if (i >= 0) lista[i] = producto;
    }
  }

  /// Categorías que devuelve la base; por defecto las tres de prueba.
  List<Categoria> categoriasDisponibles = categoriasDePrueba;

  @override
  Future<List<Categoria>> categorias() async {
    if (categoriasError != null) throw categoriasError!;
    return categoriasDisponibles;
  }

  void _comprobarCodigoLibre(String idComercio, String? codigo) {
    if (codigo == null) return;
    final repetido =
        deComercio(idComercio).any((p) => p.codigoBarras == codigo);
    if (repetido) {
      throw const AuthFailure('Ya tienes un producto con ese código de barras.');
    }
  }

  @override
  Future<Producto> crear(String idComercio, ProductoDatos datos) async {
    if (crearError != null) throw crearError!;
    _comprobarCodigoLibre(idComercio, datos.codigoBarras);
    creados.add((idComercio: idComercio, datos: datos));
    final producto = _armar(datos);
    deComercio(idComercio).insert(0, producto);
    return producto;
  }

  @override
  Future<Producto> editar(String idProducto, ProductoDatos datos) async {
    if (editarError != null) throw editarError!;
    for (final lista in productosPorComercio.values) {
      final i = lista.indexWhere((p) => p.id == idProducto);
      if (i < 0) continue;
      final actualizado = _armar(datos, id: idProducto);
      lista[i] = actualizado;
      return actualizado;
    }
    throw const AuthFailure('No encontramos ese producto.');
  }

  @override
  Future<void> eliminar(String idProducto) async {
    if (eliminarError != null) throw eliminarError!;
    for (final lista in productosPorComercio.values) {
      final antes = lista.length;
      lista.removeWhere((p) => p.id == idProducto);
      if (lista.length != antes) return;
    }
    throw const AuthFailure('No encontramos ese producto.');
  }

  @override
  Future<Set<String>> codigosExistentes(
    String idComercio,
    List<String> codigos,
  ) async {
    consultasDeCodigos.add(codigos);
    return {
      for (final p in deComercio(idComercio))
        if (p.codigoBarras != null && codigos.contains(p.codigoBarras))
          p.codigoBarras!,
    };
  }

  @override
  Future<void> crearVarios(
    String idComercio,
    List<ProductoDatos> productos,
  ) async {
    crearVariosCalls++;
    if (crearVariosError != null) throw crearVariosError!;
    for (final datos in productos) {
      creados.add((idComercio: idComercio, datos: datos));
      deComercio(idComercio).insert(0, _armar(datos));
    }
  }
}

/// Selector de archivos que entrega el [archivo] indicado (o `null`, como si
/// la persona cancelara).
class FakeSelectorArchivoCsv implements SelectorArchivoCsv {
  ArchivoCsv? archivo;
  Object? error;
  int llamadas = 0;

  @override
  Future<ArchivoCsv?> elegir() async {
    llamadas++;
    if (error != null) throw error!;
    return archivo;
  }
}

/// Selector de fotos en memoria (HU-11): devuelve [foto] o lanza [error].
class FakeSelectorImagen implements SelectorImagen {
  ImagenProducto? foto;
  Object? error;
  int llamadas = 0;

  @override
  Future<ImagenProducto?> elegir() async {
    llamadas++;
    if (error != null) throw error!;
    return foto;
  }
}

/// Precios, promociones e historial en memoria (HU-11). Imita a la base:
/// fija la fecha y la fuente "comercio" y escribe el historial solo cuando
/// cambia el precio o la disponibilidad.
class FakePreciosRepository implements PreciosRepository {
  final precios = <String, PrecioProducto>{};
  final promociones = <String, Promocion>{};
  final historiales = <String, List<RegistroPrecio>>{};
  final guardados = <({String idProducto, PrecioDatos datos})>[];
  Object? leerError;
  Object? guardarError;
  Object? promocionError;
  DateTime fecha = DateTime(2026, 11, 15, 14, 5);
  int quitarCalls = 0;

  /// Deja un precio guardado sin pasar por los casos de uso.
  void precargar(String idProducto, int precio, {bool disponible = true}) {
    precios[idProducto] = PrecioProducto(
      idProducto: idProducto,
      precio: precio,
      disponible: disponible,
      fuente: FuentePrecio.comercio,
      actualizadoEn: fecha,
    );
  }

  @override
  Future<PrecioProducto?> precio(String idProducto) async {
    final error = leerError;
    if (error != null) throw error;
    return precios[idProducto];
  }

  @override
  Future<Promocion?> promocion(String idProducto) async {
    final error = leerError;
    if (error != null) throw error;
    return promociones[idProducto];
  }

  @override
  Future<List<RegistroPrecio>> historial(
    String idProducto, {
    int limite = 10,
  }) async {
    final error = leerError;
    if (error != null) throw error;
    final lista = historiales[idProducto] ?? const [];
    return lista.reversed.take(limite).toList();
  }

  @override
  Future<PrecioProducto> guardarPrecio(
    String idProducto,
    PrecioDatos datos,
  ) async {
    final error = guardarError;
    if (error != null) throw error;
    guardados.add((idProducto: idProducto, datos: datos));
    final anterior = precios[idProducto];
    final guardado = PrecioProducto(
      idProducto: idProducto,
      precio: datos.precio,
      disponible: datos.disponible,
      fuente: FuentePrecio.comercio,
      actualizadoEn: fecha,
    );
    precios[idProducto] = guardado;
    if (anterior == null ||
        anterior.precio != datos.precio ||
        anterior.disponible != datos.disponible) {
      historiales.putIfAbsent(idProducto, () => []).add(RegistroPrecio(
            precio: datos.precio,
            disponible: datos.disponible,
            fuente: FuentePrecio.comercio,
            registradoEn: fecha,
          ));
    }
    return guardado;
  }

  @override
  Future<Promocion> guardarPromocion(
    String idProducto,
    PromocionDatos datos,
  ) async {
    final error = promocionError;
    if (error != null) throw error;
    return promociones[idProducto] = Promocion(
      idProducto: idProducto,
      precioPromocional: datos.precioPromocional,
      inicio: datos.inicio,
      fin: datos.fin,
    );
  }

  @override
  Future<void> quitarPromocion(String idProducto) async {
    final error = promocionError;
    if (error != null) throw error;
    quitarCalls++;
    promociones.remove(idProducto);
  }
}

/// Agrupa los dobles y construye los Blocs con ellos.
class TestEnv {
  final auth = FakeAuthRepository();
  final profiles = FakeProfileRepository();
  final comercios = FakeComercioRepository();
  final solicitudes = FakeSolicitudesRepository();
  final notificaciones = FakeNotificacionRepository();
  final catalogo = FakeCatalogoRepository();
  final selectorCsv = FakeSelectorArchivoCsv();
  final precios = FakePreciosRepository();
  final selectorImagen = FakeSelectorImagen();

  /// "Hoy" para las promociones (HU-11): 15 de noviembre de 2026.
  DateTime ahora = DateTime(2026, 11, 15, 10);

  DecidirSolicitudUseCase get decidirSolicitud => DecidirSolicitudUseCase(
      auth: auth, profiles: profiles, solicitudes: solicitudes);
  GetSolicitudesPendientesUseCase get getPendientes =>
      GetSolicitudesPendientesUseCase(solicitudes: solicitudes);

  /// Deja la sesión iniciada con una cuenta que tiene los [roles].
  void iniciarSesionCon(Set<UserRole> roles) {
    auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    profiles.stored = profileWith(roles);
  }

  DecisionSolicitudBloc decisionBloc(Solicitud solicitud) =>
      DecisionSolicitudBloc(solicitud: solicitud, decidir: decidirSolicitud);
  PaginatedBloc<Solicitud> listaBloc(TipoSolicitud tipo, {int pageSize = 20}) =>
      PaginatedBloc<Solicitud>(
        fetchPage: (request) => getPendientes(tipo, request),
        pageSize: pageSize,
      );
  NotificacionesBloc notificacionesBloc() => NotificacionesBloc(
        noLeidas: GetNotificacionesNoLeidasUseCase(
            auth: auth, notificaciones: notificaciones),
        marcarLeidas:
            MarcarNotificacionesLeidasUseCase(notificaciones: notificaciones),
      );

  SignInUseCase get signIn => SignInUseCase(auth: auth, profiles: profiles);
  SignUpUseCase get signUp => SignUpUseCase(auth: auth, profiles: profiles);
  ActivarModoColaboradorUseCase get activarColaborador =>
      ActivarModoColaboradorUseCase(auth: auth, profiles: profiles);
  RegistrarComercioUseCase get registrarComercio =>
      RegistrarComercioUseCase(auth: auth, comercios: comercios);
  GetMiComercioUseCase get getMiComercio =>
      GetMiComercioUseCase(auth: auth, comercios: comercios);

  // HU-10: catálogo del comercio.
  GetComercioAprobadoUseCase get comercioAprobado =>
      GetComercioAprobadoUseCase(auth: auth, comercios: comercios);
  GetProductosUseCase get getProductos => GetProductosUseCase(
      comercioAprobado: comercioAprobado, catalogo: catalogo);
  GetCategoriasUseCase get getCategorias =>
      GetCategoriasUseCase(catalogo: catalogo);
  CrearProductoUseCase get crearProducto => CrearProductoUseCase(
      comercioAprobado: comercioAprobado, catalogo: catalogo);
  EditarProductoUseCase get editarProducto => EditarProductoUseCase(
      comercioAprobado: comercioAprobado, catalogo: catalogo);
  EliminarProductoUseCase get eliminarProducto => EliminarProductoUseCase(
      comercioAprobado: comercioAprobado, catalogo: catalogo);
  ElegirArchivoCsvUseCase get elegirArchivoCsv =>
      ElegirArchivoCsvUseCase(selector: selectorCsv);
  CargarProductosCsvUseCase get cargarProductosCsv => CargarProductosCsvUseCase(
      comercioAprobado: comercioAprobado, catalogo: catalogo);

  // HU-11: precios, disponibilidad y promociones.
  GetFichaPrecioUseCase get getFichaPrecio =>
      GetFichaPrecioUseCase(comercioAprobado: comercioAprobado, precios: precios);
  ActualizarPrecioUseCase get actualizarPrecio => ActualizarPrecioUseCase(
      comercioAprobado: comercioAprobado, precios: precios);
  CambiarDisponibilidadProductoUseCase get cambiarDisponibilidadProducto =>
      CambiarDisponibilidadProductoUseCase(
          comercioAprobado: comercioAprobado, precios: precios);
  GuardarPromocionUseCase get guardarPromocion => GuardarPromocionUseCase(
      comercioAprobado: comercioAprobado,
      precios: precios,
      ahora: () => ahora);
  QuitarPromocionUseCase get quitarPromocion => QuitarPromocionUseCase(
      comercioAprobado: comercioAprobado, precios: precios);

  // HU-11: catálogo con el diseño nuevo.
  GetEncabezadoCatalogoUseCase get getEncabezado => GetEncabezadoCatalogoUseCase(
      comercioAprobado: comercioAprobado,
      categorias: getCategorias,
      catalogo: catalogo);
  GetFormularioProductoUseCase get getFormulario =>
      GetFormularioProductoUseCase(
          comercioAprobado: comercioAprobado, categorias: getCategorias);
  ElegirFotoProductoUseCase get elegirFoto =>
      ElegirFotoProductoUseCase(selector: selectorImagen);
  GuardarProductoUseCase get guardarProducto => GuardarProductoUseCase(
        crear: crearProducto,
        editar: editarProducto,
        actualizarPrecio: actualizarPrecio,
        comercioAprobado: comercioAprobado,
        catalogo: catalogo,
      );

  /// Deja la sesión iniciada como dueño de un comercio con el [estado] dado
  /// (el comercio de prueba tiene el id `c1`).
  void iniciarSesionComoComercio(ApprovalStatus estado) {
    auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    comercios.stored = comercioConEstado(estado);
  }

  CatalogoListaBloc productosBloc({int pageSize = 20}) =>
      CatalogoListaBloc(getProductos: getProductos, pageSize: pageSize);
  InventarioBloc inventarioBloc() => InventarioBloc(
        encabezado: getEncabezado,
        disponibilidad: cambiarDisponibilidadProducto,
        eliminar: eliminarProducto,
      );
  ProductoFormBloc productoFormBloc({Producto? editando}) => ProductoFormBloc(
        editando: editando,
        formulario: getFormulario,
        guardar: guardarProducto,
        eliminar: eliminarProducto,
        elegirFoto: elegirFoto,
      );
  PrecioProductoBloc precioBloc(Producto producto) => PrecioProductoBloc(
        producto: producto,
        ficha: getFichaPrecio,
        disponibilidad: cambiarDisponibilidadProducto,
        guardarPromocion: guardarPromocion,
        quitarPromocion: quitarPromocion,
      );
  CargaCsvBloc cargaCsvBloc() =>
      CargaCsvBloc(elegir: elegirArchivoCsv, cargar: cargarProductosCsv);

  LoginBloc loginBloc() => LoginBloc(signIn: signIn);
  RegisterBloc registerBloc() => RegisterBloc(signUp: signUp);
  SessionBloc sessionBloc() => SessionBloc(
        getMyProfile: GetMyProfileUseCase(auth: auth, profiles: profiles),
        signOut: SignOutUseCase(auth: auth),
      );
  CambiarDisponibilidadUseCase get cambiarDisponibilidad =>
      CambiarDisponibilidadUseCase(auth: auth, profiles: profiles);
  DisponibilidadBloc disponibilidadBloc({bool inicial = false}) =>
      DisponibilidadBloc(cambiar: cambiarDisponibilidad, inicial: inicial);

  ColaboradorOnboardingBloc colaboradorBloc() =>
      ColaboradorOnboardingBloc(activar: activarColaborador);
  ComercioBloc comercioBloc() =>
      ComercioBloc(getMine: getMiComercio, registrar: registrarComercio);
}
