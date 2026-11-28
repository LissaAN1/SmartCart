import 'package:smartcart/features/ubicacion/domain/entities/preferencia_ubicacion.dart';
import 'package:smartcart/core/pagination/paged_result.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/calificaciones/domain/entities/calificacion.dart';
import 'package:smartcart/features/calificaciones/domain/repository/calificaciones_repository.dart';
import 'package:smartcart/features/calificaciones/domain/usecases/calificar_orden_usecase.dart';
import 'package:smartcart/features/calificaciones/presentation/bloc/calificar_orden_bloc.dart';
import 'package:smartcart/features/comercio/domain/entities/comercio.dart';
import 'package:smartcart/features/orders/domain/entities/estado_orden.dart';
import 'package:smartcart/features/orders/domain/entities/orden.dart';
import 'package:smartcart/features/orders/domain/entities/plan_compra.dart';
import 'package:smartcart/features/orders/domain/entities/tipo_entrega.dart';
import 'package:smartcart/features/orders/domain/repository/compras_repository.dart';
import 'package:smartcart/features/orders/domain/usecases/compras_usecases.dart';
import 'package:smartcart/features/orders/presentation/bloc/confirmar_compra_bloc.dart';

import 'fakes.dart';
import 'fakes_cliente.dart';
import 'fakes_ubicacion.dart';

// ───────────────────────── Datos de ejemplo ─────────────────────────

/// Lo que la base devolvería para cada producto del carrito de ejemplo:
/// arroz y leche de "La Esquina" (recogida y entrega) y café de "Doña Rosa"
/// (solo recogida). Una prueba cambia uno para simular un establecimiento sin
/// registro (`idComercio` nulo).

Map<String, LineaPrevia> catalogoDeCompras() => {
      'p1': const LineaPrevia(
        idComercio: 'c1',
        establecimiento: 'Minimercado La Esquina',
        servicio: ServicioComercio.ambos,
        linea: LineaCompra(
          idProducto: 'p1',
          nombre: 'Arroz blanco 500 g',
          cantidad: 1,
          precioUnitario: 3000,
        ),
      ),
      'p2': const LineaPrevia(
        idComercio: 'c1',
        establecimiento: 'Minimercado La Esquina',
        servicio: ServicioComercio.ambos,
        linea: LineaCompra(
          idProducto: 'p2',
          nombre: 'Leche entera 1 L',
          cantidad: 1,
          precioUnitario: 4500,
        ),
      ),
      'p3': const LineaPrevia(
        idComercio: 'c2',
        establecimiento: 'Tienda Doña Rosa',
        servicio: ServicioComercio.recogida,
        linea: LineaCompra(
          idProducto: 'p3',
          nombre: 'Café molido 500 g',
          cantidad: 1,
          precioUnitario: 12000,
        ),
      ),
    };

Orden ordenDePrueba({
  String id = 'o1',
  int numero = 1001,
  String comercio = 'Minimercado La Esquina',
  EstadoOrden estado = EstadoOrden.entregada,
  TipoEntrega tipoEntrega = TipoEntrega.recogida,
  int total = 10500,
  bool tieneRepartidor = false,
  bool calificadaComercio = false,
  bool calificadaRepartidor = false,
}) =>
    Orden(
      id: id,
      numero: numero,
      comercio: comercio,
      estado: estado,
      tipoEntrega: tipoEntrega,
      total: total,
      creadoEn: DateTime(2026, 11, 15, 10, 30),
      tieneRepartidor: tieneRepartidor,
      calificadaComercio: calificadaComercio,
      calificadaRepartidor: calificadaRepartidor,
    );

// ───────────────────────────── Dobles ─────────────────────────────

/// Compras en memoria. Confirmar genera una orden por comercio, todas en
/// "Orden generada", como `confirmar_compra` en la base.
class FakeComprasRepository implements ComprasRepository {
  /// Lo que devuelve la base por producto (con cantidad 1; la cantidad pedida
  /// se aplica al responder).
  final catalogo = catalogoDeCompras();

  /// Las órdenes del cliente, de la más reciente a la más antigua.
  final ordenes = <Orden>[];

  Object? previsualizarError;
  Object? confirmarError;
  Object? ordenesError;
  int previsualizarCalls = 0;
  int confirmarCalls = 0;

  /// Lo que recibió la última llamada a `confirmar`.
  List<LineaSolicitud>? ultimasLineas;
  Map<String, EleccionEntrega>? ultimasElecciones;
  List<String>? ultimoQuitarDelCarrito;

  /// Lo comprado sale del carrito (lo conecta el entorno de pruebas).
  void Function(List<String> idsDelCarrito)? alConfirmar;

  int _siguienteNumero = 1001;

  @override
  Future<List<LineaPrevia>> previsualizar(List<LineaSolicitud> lineas) async {
    previsualizarCalls++;
    if (previsualizarError != null) throw previsualizarError!;
    return [
      for (final l in lineas)
        if (catalogo[l.idProducto] case final previa?)
          LineaPrevia(
            idComercio: previa.idComercio,
            establecimiento: previa.establecimiento,
            servicio: previa.servicio,
            linea: LineaCompra(
              idProducto: l.idProducto,
              nombre: previa.linea.nombre,
              cantidad: l.cantidad,
              precioUnitario: previa.linea.precioUnitario,
              disponible: previa.linea.disponible,
            ),
          ),
    ];
  }

  @override
  Future<List<OrdenGenerada>> confirmar(
    List<LineaSolicitud> lineas,
    Map<String, EleccionEntrega> elecciones, {
    List<String>? quitarDelCarrito,
  }) async {
    confirmarCalls++;
    ultimasLineas = lineas;
    ultimasElecciones = elecciones;
    ultimoQuitarDelCarrito = quitarDelCarrito;
    if (confirmarError != null) throw confirmarError!;
    final porComercio = <String, int>{};
    final nombres = <String, String>{};
    for (final l in lineas) {
      final previa = catalogo[l.idProducto]!;
      final id = previa.idComercio!;
      nombres[id] = previa.establecimiento;
      porComercio[id] =
          (porComercio[id] ?? 0) + previa.linea.precioUnitario! * l.cantidad;
    }
    final generadas = <OrdenGenerada>[];
    for (final e in porComercio.entries) {
      final eleccion = elecciones[e.key] ?? EleccionEntrega.recogida;
      final orden = OrdenGenerada(
        id: 'o$_siguienteNumero',
        numero: _siguienteNumero++,
        idComercio: e.key,
        comercio: nombres[e.key]!,
        tipoEntrega: eleccion.tipo,
        total: e.value,
      );
      generadas.add(orden);
      ordenes.insert(
        0,
        ordenDePrueba(
          id: orden.id,
          numero: orden.numero,
          comercio: orden.comercio,
          estado: EstadoOrden.generada,
          tipoEntrega: orden.tipoEntrega,
          total: orden.total,
        ),
      );
    }
    // Como la base: sin la lista, sale del carrito lo comprado.
    alConfirmar?.call(
        quitarDelCarrito ?? [for (final l in lineas) l.idProducto]);
    return generadas;
  }

  @override
  Future<PagedResult<Orden>> misOrdenes(PageRequest request) async {
    if (ordenesError != null) throw ordenesError!;
    final filas =
        ordenes.skip(request.from).take(request.pageSize + 1).toList();
    return PagedResult.fromRows(filas, request);
  }
}

/// Calificaciones en memoria. Aplica la regla de "una vez por orden y tipo" y
/// calcula el promedio con lo recibido.
class FakeCalificacionesRepository implements CalificacionesRepository {
  final enviadas = <({String idOrden, TipoCalificacion tipo, int estrellas, String? comentario})>[];
  Object? error;
  int calls = 0;

  @override
  Future<ResumenCalificaciones> calificar({
    required String idOrden,
    required TipoCalificacion tipo,
    required int estrellas,
    String? comentario,
  }) async {
    calls++;
    if (error != null) throw error!;
    if (enviadas.any((e) => e.idOrden == idOrden && e.tipo == tipo)) {
      throw const AuthFailure('Ya calificaste esta orden.');
    }
    enviadas.add((
      idOrden: idOrden,
      tipo: tipo,
      estrellas: estrellas,
      comentario: comentario,
    ));
    final todas = enviadas.where((e) => e.tipo == tipo).toList();
    final suma = todas.fold<int>(0, (s, e) => s + e.estrellas);
    return ResumenCalificaciones(
      promedio: suma / todas.length,
      total: todas.length,
    );
  }
}

/// Los dobles de órdenes y calificaciones de un [TestEnv].
class OrdenesFakes {
  final compras = FakeComprasRepository();
  final calificaciones = FakeCalificacionesRepository();
}

final _fakesDeOrdenes = Expando<OrdenesFakes>('fakesDeOrdenes');

/// Casos de uso y Blocs de la compra (HU-20) y de las calificaciones (HU-25)
/// construidos con los dobles del entorno.
extension EntornoOrdenes on TestEnv {
  OrdenesFakes get ordenes => _fakesDeOrdenes[this] ??= (OrdenesFakes()
    ..compras.alConfirmar = (ids) {
      cliente.carrito.lineas.removeWhere((i) => ids.contains(i.idProducto));
    });

  /// Sesión de cliente con el carrito de ejemplo ya sembrado en la base
  /// falsa; el carrito arranca vacío.
  void iniciarSesionComoClienteConCompras() {
    iniciarSesionComoCliente();
    cliente.carrito.disponibles.addAll({
      for (final p in [arrozCliente, lecheCliente, cafeCliente]) p.id: p,
    });
  }

  /// Agrega al carrito [cantidades] (id → unidades).
  void llenarCarrito(Map<String, int> cantidades) {
    final todos = {
      for (final p in [arrozCliente, lecheCliente, cafeCliente]) p.id: p,
    };
    cantidades.forEach((id, cantidad) {
      cliente.carrito.lineas.add(todos[id]!.toLinea(cantidad));
    });
  }

  GetPlanCompraUseCase get getPlanCompra =>
      GetPlanCompraUseCase(carrito: getCarrito, compras: ordenes.compras);
  ConfirmarCompraUseCase get confirmarCompra => ConfirmarCompraUseCase(
      cliente: clienteActivo,
      compras: ordenes.compras,
      ubicacion: getMiUbicacion);

  /// Deja guardada la ubicación del cliente (HU-19): sin ella no hay entrega.
  void guardarUbicacionDelCliente({String? direccion}) =>
      ubicacion.repositorio.guardada = PreferenciaUbicacion(
        ubicacion: ubicacionCliente,
        radioM: 5000,
        direccion: direccion,
      );
  GetMisOrdenesUseCase get getMisOrdenes =>
      GetMisOrdenesUseCase(cliente: clienteActivo, compras: ordenes.compras);
  CalificarOrdenUseCase get calificarOrden => CalificarOrdenUseCase(
      cliente: clienteActivo, calificaciones: ordenes.calificaciones);

  ConfirmarCompraBloc confirmarCompraBloc() => ConfirmarCompraBloc(
        obtenerPlan: getPlanCompra,
        confirmar: confirmarCompra,
        ubicacion: getMiUbicacion,
      );

  PaginatedBloc<Orden> misOrdenesBloc() => PaginatedBloc<Orden>(
        fetchPage: getMisOrdenes.call,
        errorMessageFor: mensajeDeFallo,
      );

  CalificarOrdenBloc calificarOrdenBloc(
    String idOrden,
    TipoCalificacion tipo,
  ) =>
      CalificarOrdenBloc(
        calificar: calificarOrden,
        idOrden: idOrden,
        tipo: tipo,
      );
}
